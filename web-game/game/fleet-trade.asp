<% option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "fleets"

dim can_command_alliance_fleets : can_command_alliance_fleets = -1

if not IsNull(AllianceId) and hasRight("can_order_other_fleets") then
	can_command_alliance_fleets = AllianceId
end if

dim fleet_owner_id : fleet_owner_id = UserID

sub RetrieveFleetOwnerId(fleetid)
	dim oRs, buildingsRs, query

	' retrieve fleet owner
	query = "SELECT ownerid" &_
			" FROM vw_fleets as f" &_
			" WHERE (ownerid=" & UserID & " OR (shared AND owner_alliance_id=" & can_command_alliance_fleets & ")) AND id=" & fleetid
	set oRs = oConn.Execute(query)

	fleet_owner_id = oRs(0)
end sub

' display fleet info
sub DisplayExchangeForm(fleetid)
	dim content
	set content = GetTemplate("fleet-trade")

	dim oRs, query

	' retrieve fleet name, size, position, destination
	query = "SELECT id, name, attackonsight, engaged, size, signature, speed, remaining_time, commanderid, commandername," &_
			" planetid, planet_name, planet_galaxy, planet_sector, planet_planet, planet_ownerid, planet_owner_name, planet_owner_relation," &_
		    " cargo_capacity, cargo_ore, cargo_hydrocarbon, cargo_scientists, cargo_soldiers, cargo_workers" & _
			" FROM vw_fleets" &_
			" WHERE ownerid=" & fleet_owner_id & " AND id="&fleetid
	set oRs = oConn.Execute(query)

	' if fleet doesn't exist, redirect to the list of fleets
	if oRs.EOF then
		if Request.QueryString("a") = "open" then
			Response.End
		else
			Response.Redirect "fleets.asp"
			Response.End
		end if
	end if

	dim relation
	relation = oRs(17)


	' if fleet is moving or engaged, go back to the fleets
	if not isnull(oRs(7)) or oRs(3) then
		if Request.QueryString("a") = "open" then
			relation = rWar
		else
			Response.Redirect "fleet.asp?id=" & fleetid
			Response.End
		end if
	end if

	content.AssignValue "fleetid", fleetid
	content.AssignValue "fleetname", oRs(1)
	content.AssignValue "size", oRs(4)
	content.AssignValue "speed", oRs(6)


	content.AssignValue "fleet_capacity", oRs(18)
	content.AssignValue "fleet_ore", oRs(19)
	content.AssignValue "fleet_hydrocarbon", oRs(20)
	content.AssignValue "fleet_scientists", oRs(21)
	content.AssignValue "fleet_soldiers", oRs(22)
	content.AssignValue "fleet_workers", oRs(23)

	content.AssignValue "fleet_load", oRs(19) + oRs(20) + oRs(21) + oRs(22) + oRs(23)


	select case relation
		case rSelf
			' retrieve planet ore, hydrocarbon, workers, relation
			query = "SELECT ore, hydrocarbon, scientists, soldiers," &_
					" GREATEST(0, workers-GREATEST(workers_busy,workers_for_maintenance-workers_for_maintenance/2+1,500))," &_
					" workers > workers_for_maintenance/2" &_
					" FROM vw_planets WHERE id="&oRs(10)
			set oRs = oConn.Execute(query)

			content.AssignValue "planet_ore", oRs(0)
			content.AssignValue "planet_hydrocarbon", oRs(1)
			content.AssignValue "planet_scientists", oRs(2)
			content.AssignValue "planet_soldiers", oRs(3)
			content.AssignValue "planet_workers", oRs(4)

			if not oRs(5) then
				content.AssignValue "planet_ore", 0
				content.AssignValue "planet_hydrocarbon", 0
				content.Parse "load.not_enough_workers_to_load"
			end if

			content.Parse "load"
		case rFriend, rAlliance, rHostile

			content.Parse "unload"
		case else
			content.Parse "cargo"
	end select

	content.Parse ""
	Response.Write content.Output
end sub

sub TransferResources(fleetid)
	dim oRs, ore, hydrocarbon, scientists, soldiers, workers

	ore = ToInt(Request.QueryString("load_ore"), 0) - ToInt(Request.QueryString("unload_ore"), 0)
	hydrocarbon = ToInt(Request.QueryString("load_hydrocarbon"), 0) - ToInt(Request.QueryString("unload_hydrocarbon"), 0)
	scientists = ToInt(Request.QueryString("load_scientists"), 0) - ToInt(Request.QueryString("unload_scientists"), 0)
	soldiers = ToInt(Request.QueryString("load_soldiers"), 0) - ToInt(Request.QueryString("unload_soldiers"), 0)
	workers = ToInt(Request.QueryString("load_workers"), 0) - ToInt(Request.QueryString("unload_workers"), 0)

	if ore <> 0 or hydrocarbon <> 0 or scientists <> 0 or soldiers <> 0 or workers <> 0 then
		set oRs = oConn.Execute("SELECT sp_transfer_resources_with_planet(" & fleet_owner_id & "," & fleetid & "," & ore & "," & hydrocarbon & "," & scientists & "," & soldiers & "," & workers & ")")
	end if
end sub

sub TransferResourcesViaPost(fleetid)
	dim oRs, ore, hydrocarbon, scientists, soldiers, workers

	ore = ToInt(Request.Form("load_ore"), 0) - ToInt(Request.Form("unload_ore"), 0)
	hydrocarbon = ToInt(Request.Form("load_hydrocarbon"), 0) - ToInt(Request.Form("unload_hydrocarbon"), 0)
	scientists = ToInt(Request.Form("load_scientists"), 0) - ToInt(Request.Form("unload_scientists"), 0)
	soldiers = ToInt(Request.Form("load_soldiers"), 0) - ToInt(Request.Form("unload_soldiers"), 0)
	workers = ToInt(Request.Form("load_workers"), 0) - ToInt(Request.Form("unload_workers"), 0)

	if ore <> 0 or hydrocarbon <> 0 or scientists <> 0 or soldiers <> 0 or workers <> 0 then
		set oRs = oConn.Execute("SELECT sp_transfer_resources_with_planet(" & fleet_owner_id & "," & fleetid & "," & ore & "," & hydrocarbon & "," & scientists & "," & soldiers & "," & workers & ")")
		Response.Redirect "fleet.asp?id=" & fleetid & "&trade=" & oRs(0).value
		Response.End
	end if
end sub

dim fleetid
fleetid = ToInt(Request.QueryString("id"), 0)

if fleetid = 0 then
	Response.Redirect "fleets.asp"
	Response.End
end if

RetrieveFleetOwnerId(fleetid)

TransferResourcesViaPost(fleetid)

if Request.QueryString("a") <> "open" then
	Response.Redirect "fleet.asp?id=" & fleetid
	Response.End
end if

TransferResources(fleetid)

DisplayExchangeForm(fleetid)

%>