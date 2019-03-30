<%@LANGUAGE="JSCRIPT"%>
<%
Session.Abandon();
Response.Cookies('authID') = '';
Response.Cookies('authID').domain = '.exil.pw';
Response.Redirect('/');
%>