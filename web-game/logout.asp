<%
if Request.QueryString("sid") = Session.SessionID then Session.Abandon
Response.Redirect("/")
%>