<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "training"

showHeader = true

dim train_error
train_error = 0

sub DisplayTraining()
	dim query, oRs
	dim underResearchCount

	dim content
	set content = GetTemplate("training")

	content.AssignValue "planetid", CurrentPlanet

	query = "SELECT scientist_ore, scientist_hydrocarbon, scientist_credits," &_
			" soldier_ore, soldier_hydrocarbon, soldier_credits" &_
			" FROM sp_get_training_price(" & UserId & ")"
	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		content.AssignValue "scientist_ore", oRs(0)
		content.AssignValue "scientist_hydrocarbon", oRs(1)
		content.AssignValue "scientist_credits", oRs(2)
		content.AssignValue "soldier_ore", oRs(3)
		content.AssignValue "soldier_hydrocarbon", oRs(4)
		content.AssignValue "soldier_credits", oRs(5)
	end if

	query = "SELECT scientists, scientists_capacity, soldiers, soldiers_capacity, workers FROM vw_planets WHERE id="&CurrentPlanet
	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		content.AssignValue "scientists", oRs(0)
		content.AssignValue "scientists_capacity", oRs(1)

		content.AssignValue "soldiers", oRs(2)
		content.AssignValue "soldiers_capacity", oRs(3)
		if oRs(2)*250 < oRs(0)+oRs(4) then content.Parse "not_enough_soldiers"

		if oRs(0) < oRs(1) then
			content.Parse "input_scientists"
		else
			content.Parse "max_scientists"
		end if

		if oRs(2) < oRs(3) then
			content.Parse "input_soldiers"
		else
			content.Parse "max_soldiers"
		end if
	end if

	if train_error <> 0 then
		if train_error = 5 then content.Parse "error.cant_train_now" else content.Parse "error.not_enough_workers"

		content.Parse "error"
	end if

	dim i

	' training in process
	query = "SELECT id, scientists, soldiers, int4(date_part('epoch', end_time-now()))" &_
			" FROM planet_training_pending WHERE planetid="&CurrentPlanet&" AND end_time IS NOT NULL" &_
			" ORDER BY start_time"
	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF
		content.AssignValue "queueid", oRs(0)
		content.AssignValue "remainingtime", oRs(3)

		if oRs(1) > 0 then
			content.AssignValue "quantity", oRs(1)
			content.Parse "training.item.scientists"
		end if

		if oRs(2) > 0 then
			content.AssignValue "quantity", oRs(2)
			content.Parse "training.item.soldiers"
		end if

		content.Parse "training.item"

		i = i + 1
		oRs.MoveNext
	wend

	if i > 0 then content.Parse "training"

	' queue
	query = "SELECT planet_training_pending.id, planet_training_pending.scientists, planet_training_pending.soldiers," &_
			"	int4(ceiling(1.0*planet_training_pending.scientists/GREATEST(1, training_scientists)) * date_part('epoch', INTERVAL '1 hour'))," &_
			"	int4(ceiling(1.0*planet_training_pending.soldiers/GREATEST(1, training_soldiers)) * date_part('epoch', INTERVAL '1 hour'))" &_
			" FROM planet_training_pending" &_
			"	JOIN nav_planet ON (nav_planet.id=planet_training_pending.planetid)" &_
			" WHERE planetid="&CurrentPlanet&" AND end_time IS NULL" &_
			" ORDER BY start_time"
	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF
		content.AssignValue "queueid", oRs(0)

		if oRs(1) > 0 then
			content.AssignValue "quantity", oRs(1)
			content.AssignValue "remainingtime", oRs(3)
			content.Parse "queue.item.scientists"
		end if

		if oRs(2) > 0 then
			content.AssignValue "quantity", oRs(2)
			content.AssignValue "remainingtime", oRs(4)
			content.Parse "queue.item.soldiers"
		end if

		content.Parse "queue.item"

		i = i + 1
		oRs.MoveNext
	wend

	if i > 0 then content.Parse "queue"

	content.Parse ""

	Display(content)
end sub

sub Train(Scientists, Soldiers)
	dim oRs
	set oRs = ConnExecuteRetry("SELECT * FROM sp_start_training(" & UserId & "," & CurrentPlanet & "," & Scientists & "," & Soldiers & ")")

	if not oRs.EOF then
		train_error = oRs(0)
	else
		train_error = 1
	end if
end sub

sub CancelTraining(queueId)
	connExecuteRetryNoRecords "SELECT * FROM sp_cancel_training(" & CurrentPlanet & ", " & QueueId & ")"
	Response.Redirect "?"
	Response.end
end sub

dim Action, trainScientists, trainSoldiers, queueId

Action = lcase(Request.QueryString("a"))
trainScientists = ToInt(Request.Form("scientists"),0)
trainSoldiers = ToInt(Request.Form("soldiers"),0)
queueId = ToInt(Request.QueryString("q"),0)

select case Action
	case "train"
		Train trainScientists, trainSoldiers
	case "cancel"
		CancelTraining queueId
end select

DisplayTraining()

%>