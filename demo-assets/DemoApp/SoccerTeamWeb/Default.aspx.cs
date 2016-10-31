using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.SqlClient;

namespace SoccerTeamWeb
{
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
         
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            SqlConnection Conn = null;
            try
            {
                string databaseName = "MySoccerTeam";
                string datasource = Request["txtRDSInstance"].ToString();
                string user = Request["txtUser"].ToString();
                string password = Request["txtPassword"].ToString();
                string connString = string.Format("Data Source={0};User ID={1};Password={2};", datasource, user, password);
                Conn = new SqlConnection(connString);
                Conn.Open();

                CreateDatabase(Conn, databaseName);

                WriteContent(Conn, databaseName);
            }
            catch (Exception ex)
            {
                Response.Write(ex.Message);
            }
            finally
            {
                Conn.Close();
                Conn.Dispose();
            }
        }

        private void CreateDatabase(SqlConnection Conn, string databaseName)
        {
            try
            {
                string listDatabases = "SELECT name FROM master.dbo.sysdatabases";
                bool dbFound = false;

                SqlCommand cmd = new SqlCommand(listDatabases, Conn);
                SqlDataReader myDr = cmd.ExecuteReader();

                while(myDr.Read())
                {                   
                    if (myDr["name"].ToString() == databaseName)
                    {
                        dbFound = true;
                        continue;
                    }
                }
                myDr.Close();

                string createDBQuery = string.Format("CREATE DATABASE {0}",databaseName);
                string createDBTable = string.Format("CREATE TABLE {0}.dbo.Players(Name nvarchar(100) NOT NULL, Age int NOT NULL, Goals int NOT NULL, Position nvarchar(50) NOT NULL)",databaseName);
                
               if (!dbFound)
                {
                    cmd = new SqlCommand(createDBQuery, Conn);
                    cmd.ExecuteNonQuery();

                    cmd = new SqlCommand(createDBTable, Conn);
                    cmd.ExecuteNonQuery();

                    cmd = new SqlCommand(string.Format("INSERT INTO {0}.dbo.Players VALUES ('Katie',8,5,'Forward')",databaseName), Conn);
                    cmd.ExecuteNonQuery();
                    cmd = new SqlCommand(string.Format("INSERT INTO {0}.dbo.Players VALUES ('Emma Grace', 9,9, 'Forward')", databaseName), Conn);
                    cmd.ExecuteNonQuery();
                    cmd = new SqlCommand(string.Format("INSERT INTO {0}.dbo.Players VALUES ('Maci',8,14,'Defense')", databaseName), Conn);
                    cmd.ExecuteNonQuery();
                    cmd = new SqlCommand(string.Format("INSERT INTO {0}.dbo.Players VALUES ('Libby',8,18,'Forward')", databaseName), Conn);
                    cmd.ExecuteNonQuery();
                    cmd = new SqlCommand(string.Format("INSERT INTO {0}.dbo.Players VALUES ('Alyssa',6,1,'Forward')", databaseName), Conn);
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                Response.Write(ex.Message.ToString());
            }
        }

        private void WriteContent(SqlConnection Conn, string databaseName)
        {
            try
            {
                string strSQL = string.Format("SELECT Name,Age,Goals,Position from {0}.dbo.Players",databaseName);
                SqlCommand DBCmd = new SqlCommand(strSQL, Conn);
                SqlDataReader myDataReader;
                myDataReader = DBCmd.ExecuteReader();

                Response.Write("<table cellpadding='5'><tr><td align='center'><u>All Star</u></td><td align='center'><u>Name</u></td><td align='center'><u>Age</u></td><td align='center'><u>Goals</u></td><td align='center'><u>Position</u></td></tr>");
                while (myDataReader.Read())
                {
                    Response.Write("<tr>");
                    Response.Write("<td align='center'>");
                    if ((int)myDataReader["Goals"] >= 5)
                    {
                        Response.Write("<img height='25' width='25' src='/star-icon.png' />");
                    }
                    Response.Write("</td>");
                    Response.Write("<td align='center'>" + myDataReader["Name"].ToString() + "</td>");
                    Response.Write("<td align='center'>" + myDataReader["Age"].ToString() + "</td>");
                    Response.Write("<td align='center'>" + myDataReader["Goals"].ToString() + "</td>");
                    Response.Write("<td align='center'>" + myDataReader["Position"].ToString() + "</td>");
                    Response.Write("</tr>");

                }
                Response.Write("</table><br/><br/>");
                myDataReader.Close();
            }
            catch (Exception ex)
            {
                Response.Write(ex.Message);
            }
        }
    }
}