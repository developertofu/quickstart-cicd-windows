<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SoccerTeamWeb.Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        SQL Server DNS:
        <asp:TextBox ID="txtRDSInstance" runat="server"></asp:TextBox>
&nbsp;user:
        <asp:TextBox ID="txtUser" runat="server"></asp:TextBox>
&nbsp;password:
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"></asp:TextBox>
&nbsp;<asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="Get Players" />
    
    </div>
    </form>
</body>
</html>
