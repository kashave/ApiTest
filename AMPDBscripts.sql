USE [AMP]
GO
/****** Object:  User [amp_qa]    Script Date: 2/14/2022 7:02:42 AM ******/
CREATE USER [amp_qa] FOR LOGIN [amp_qa] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [ampuser]    Script Date: 2/14/2022 7:02:42 AM ******/
CREATE USER [ampuser] FOR LOGIN [ampuser] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [CHECKFREE\F8B340G]    Script Date: 2/14/2022 7:02:42 AM ******/
CREATE USER [CHECKFREE\F8B340G] FOR LOGIN [CHECKFREE\F8B340G] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [NT SERVICE\SQLSERVERAGENT]    Script Date: 2/14/2022 7:02:42 AM ******/
CREATE USER [NT SERVICE\SQLSERVERAGENT] FOR LOGIN [NT SERVICE\SQLSERVERAGENT] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [amp_qa]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [amp_qa]
GO
ALTER ROLE [db_datareader] ADD MEMBER [amp_qa]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [amp_qa]
GO
ALTER ROLE [db_owner] ADD MEMBER [ampuser]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [ampuser]
GO
ALTER ROLE [db_datareader] ADD MEMBER [ampuser]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [ampuser]
GO
ALTER ROLE [db_owner] ADD MEMBER [CHECKFREE\F8B340G]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [CHECKFREE\F8B340G]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [CHECKFREE\F8B340G]
GO
ALTER ROLE [db_datareader] ADD MEMBER [CHECKFREE\F8B340G]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [CHECKFREE\F8B340G]
GO
/****** Object:  UserDefinedFunction [dbo].[Find_Unicode]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     FUNCTION [dbo].[Find_Unicode]
(
    @in_string nvarchar(max)
)
RETURNS  @unicode_char TABLE(id INT IDENTITY(1,1), Char_ NVARCHAR(4), position BIGINT)
AS
BEGIN
    DECLARE @character nvarchar(1)
    DECLARE @index int
 
    SET @index = 1
    WHILE @index <= LEN(@in_string)
    BEGIN
        SET @character = SUBSTRING(@in_string, @index, 1)
        IF((UNICODE(@character) NOT BETWEEN 32 AND 127) AND UNICODE(@character) NOT IN (10,11))
        BEGIN
      INSERT INTO @unicode_char(Char_, position)
      VALUES(@character, @index)
    END
    SET @index = @index + 1
    END
    RETURN
END
GO
/****** Object:  UserDefinedFunction [dbo].[UdfAORFDSplitString]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		krrishnajayanthi
-- Create date: 09/12/2021
-- Description:	split selimited string to delegate name,lanid,emailid
-- =============================================


CREATE     FUNCTION [dbo].[UdfAORFDSplitString]
(    
    @Input NVARCHAR(MAX)
   
)
RETURNS @Output TABLE (FirstName NVARCHAR(100), LastName NVARCHAR(100), Email NVARCHAR(100), Lanid NVARCHAR(100)
  
)
AS
BEGIN

DECLARE @StartIndex INT, @EndIndex INT
DECLARE @Inputrow VARCHAR(max)
DECLARE @last NVARCHAR(200)
DECLARE @first NVARCHAR(200)
declare @lpos int
 
 
 SET @Input=REPLACE(@Input,CHAR(10),'|')

  IF SUBSTRING(@Input, LEN(@Input) - 1, LEN(@Input)) <> '|'
    BEGIN
        SET @Input = @Input + '|'
    END

 SET @StartIndex = 1
 WHILE CHARINDEX('|', @Input) > 0 --'|' delimiter
    BEGIN
	  SET @EndIndex = CHARINDEX('|', @Input)
	  	SELECT @Inputrow=SUBSTRING(@Input, @StartIndex, @EndIndex - 1) --row



		SET @last = (Select (Substring(reverse(@Inputrow),0,((charindex(' ', reverse(@Inputrow)))))))
		set @first= (select (SUBSTRING(@Inputrow, 0, (charindex(',',@Inputrow)))))
		set @lpos=len(@Inputrow)-(len(@first)+Len(@last))



        IF @last like '%@%'
		BEGIN
		INSERT INTO @Output(FirstName, LastName, Email)
		SELECT  SUBSTRING(@Inputrow,len(@first)+2,@lpos-2) AS FirstName,  @first AS Lastname,(REVERSE(@last)) AS  Email
		END
		ELSE

		BEGIN 
		INSERT INTO @Output(FirstName, LastName,lanid)
		SELECT SUBSTRING(@Inputrow,len(@first)+2,@lpos-2)  AS FirstName, @first AS Lastname,(REVERSE(@last)) AS  Email
		END
		 SET @Input = SUBSTRING(@Input, @EndIndex + 1, LEN(@Input))
		
	END

	--SELECT *FROM #outputsplit

    RETURN
END
GO
/****** Object:  UserDefinedFunction [dbo].[UdfDelegateSplitString]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		krrishnajayanthi
-- Create date: 09/08/2021
-- Description:	split selimited string to delegate name,lanid,emailid
-- =============================================


CREATE FUNCTION [dbo].[UdfDelegateSplitString]
(    
    @Input NVARCHAR(MAX),
    @Character CHAR(1)
)
RETURNS @Output TABLE (
   DLname NVARCHAR(100),DFname NVARCHAR(100),DLanid NVARCHAR(100),DEmail NVARCHAR(100)
)
AS
BEGIN

DECLARE @StartIndex INT, @EndIndex INT
DECLARE @strdel VARCHAR(100)
DECLARE @dLname VARCHAR(100)
DECLARE @dFname VARCHAR(100)
DECLARE @lanid VARCHAR(100)
DECLARE @emailid VARCHAR(100)
DECLARE @strlanemail VARCHAR(100)
 --CREATE TABLE #temp1 (DLname nvarchar(100),DFname nvarchar(100),DLanid nvarchar(100),DEmail nvarchar(100))

 
 SET @Input=LTRIM(RTRIM(@Input))--TRIM('Bakshi, Rana  |Test, Delegate F36B6U8|Test1, Del1 ')
 SET @Input=REPLACE(@Input,', ','&') --replaced to split names
 SET @Input=REPLACE(@Input,' ','~') --replaced to split lanid or email
 
 SET @Character='|'
 SET @StartIndex = 1

    IF SUBSTRING(@Input, LEN(@Input) - 1, LEN(@Input)) <> @Character
    BEGIN
        SET @Input = @Input + @Character
    END
 
    WHILE CHARINDEX(@Character, @Input) > 0 --'|' delimiter
    BEGIN
        SET @EndIndex = CHARINDEX(@Character, @Input)
         
		SELECT @strdel=SUBSTRING(@Input, @StartIndex, @EndIndex - 1) --row
		
		IF CHARINDEX('~',@strdel)>0  ---'~'delimiter check lanid or emailid exists
		BEGIN
	
		SET @dLname=SUBSTRING(SUBSTRING(@strdel, 0,CHARINDEX('~', @strdel)),0,CHARINDEX('&', @strdel))
		SET @dFname=SUBSTRING(SUBSTRING(@strdel, 0,CHARINDEX('~', @strdel)),CHARINDEX('&', @strdel)+1,CHARINDEX('~', @strdel))
		SET @strlanemail=SUBSTRING(@strdel,CHARINDEX('~', @strdel)+1 ,len(@strdel)+1)

				IF CHARINDEX('@',@strlanemail)>0 ---'@' delimiter for email or lanid
				BEGIN
					SET @lanid=''
					SET @emailid=@strlanemail
				END
				ELSE
				BEGIN
					SET @lanid=@strlanemail
					SET @emailid=''
				END
		END
		ELSE
		BEGIN
		
		SET @dLname=SUBSTRING(@strdel,0,CHARINDEX('&', @strdel))
		SET @dFname=SUBSTRING(@strdel,CHARINDEX('&', @strdel)+1,len(@strdel))
		SET @lanid=''
		SET @emailid=''

		END
		
        INSERT INTO @Output(DLname,DFname,DLanid,DEmail)
        SELECT @dLname,@dFname,@lanid,@emailid
         
        SET @Input = SUBSTRING(@Input, @EndIndex + 1, LEN(@Input))
    END

    RETURN
END
GO
/****** Object:  UserDefinedFunction [dbo].[UdfGetdelegate]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		krrishnajayanthi.v
-- Create date: 9/9/2021
-- Description:	get multiple delegate to one string for RFI Details
-- select  dbo.UdfGetdelegate(94)
--select  dbo.UdfGetdelegate(110)
-- =============================================
CREATE FUNCTION [dbo].[UdfGetdelegate] 
(	
	@Rfid bigint
)
RETURNS VARCHAR(1000) 
AS
BEGIN
DECLARE @delname varchar(1000)

	--SELECT @delname=STUFF((SELECT '|' + R.Lname+', '+R.Fname +'$'+CASE  WHEN R.Lanid !='' THEN + R.Lanid+ '$' ELSE '$'  + R.Emailid +'$' END
			SELECT @delname=STUFF((SELECT '$' + R.Lname+', '+R.Fname + 
		CASE  WHEN R.Lanid !='' THEN +' '+ R.Lanid+ ''
			  WHEN R.EMAILID != '' THEN +' ' + R.Emailid 
			  ELSE ''
		END
            FROM dbo.RFIdelegate R WHERE R.RFIID=@Rfid
            FOR XML PATH('')) ,1,1,'')

			return @delname
END
GO
/****** Object:  UserDefinedFunction [dbo].[UdfGetuserValidationError]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		krrishnajayanthi.v
-- Create date: 10/7/2021
-- Description:	get Valdtaionerror messgae for each user,asset and Role
--select  dbo.UdfGetuserValidationError(105)
--select  dbo.UdfGetuserValidationError(236)
-- =============================================
CREATE   FUNCTION [dbo].[UdfGetuserValidationError] 
(	
	@uid bigint
)
RETURNS VARCHAR(4000) 
AS
BEGIN
DECLARE @delname varchar(1000)
SELECT @delname=STUFF((SELECT  DISTINCT ';' +  	CASE WHEN Len(ISNULL(U.ErrorMessage,''))>0 THEN ';'+ U.ErrorMessage ELSE '' END +
									CASE WHEN Len(ISNULL(A.ErrorMessage,''))>0 THEN ';'+A.ErrorMessage ELSE '' END +
									CASE WHEN Len(ISNULL(R.ErrorMessage,''))>0 THEN ';'+R.ErrorMessage ELSE '' END       
FROM
dbo.UserRFI UR
	INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive =1
	INNER JOIN dbo.BU B ON B.ID=U.BUID
	LEFT JOIN [dbo].[UserAsset] UA ON UA.UserID=U.ID
	LEFT JOIN [dbo].[Asset] A ON A.ID=UA.AssetID AND A.IsActive =1
	LEFT JOIN [dbo].[UserRole] UR1 ON UR1.UserId=U.ID
	LEFT JOIN [dbo].[Role] R ON R.Id=UR1.Roleid AND R.IsActive =1
WHERE U.ID=@uid
FOR XML PATH('')) ,1,2,'')
			return @delname
END


GO
/****** Object:  Table [dbo].[Application]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Application](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[UAID] [varchar](50) NULL,
	[APMNumber] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_APPLICATION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BU]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BU](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[BUName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_BU] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Campaignperiod]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Campaignperiod](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CampaignID] [bigint] NOT NULL,
	[StartDt] [datetime] NOT NULL,
	[EndDt] [datetime] NOT NULL,
 CONSTRAINT [PK_CAMPAIGNPERIOD] PRIMARY KEY CLUSTERED 
(
	[CampaignID] ASC,
	[StartDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFI]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFI](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NULL,
	[RFIGroupID] [int] NULL,
	[RFITrackingID] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
	[BusinessOwner] [varchar](250) NULL,
	[DataNeeded] [int] NULL,
	[BUID] [int] NULL,
 CONSTRAINT [PK_RFI] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIApplication]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIApplication](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RFIID] [bigint] NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[AssignDt] [datetime] NULL,
	[AssignedBy] [bigint] NULL,
	[ApplicationOwnerUserid] [bigint] NULL,
 CONSTRAINT [PK_RFIAPPLICATION_1] PRIMARY KEY CLUSTERED 
(
	[RFIID] ASC,
	[ApplicationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFICampaign]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFICampaign](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RFIID] [bigint] NOT NULL,
	[CampaignID] [bigint] NOT NULL,
	[AssignDt] [datetime] NOT NULL,
 CONSTRAINT [PK_RFICAMPAIGN] PRIMARY KEY CLUSTERED 
(
	[RFIID] ASC,
	[CampaignID] ASC,
	[AssignDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIDueDt]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIDueDt](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RFIID] [bigint] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_RFIDUEDT] PRIMARY KEY CLUSTERED 
(
	[RFIID] ASC,
	[DueDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIStatus]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_RFISTAUS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIStatusLog]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIStatusLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RFIID] [bigint] NOT NULL,
	[RFIStatusID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDt] [datetime] NULL,
	[RejectTypeid] [int] NULL,
	[Comments] [varchar](5000) NULL,
 CONSTRAINT [PK_RFISTAUSLOG] PRIMARY KEY CLUSTERED 
(
	[RFIID] ASC,
	[RFIStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[User]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[User](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](250) NULL,
	[EmpID] [int] NULL,
	[ReportsTo] [bigint] NULL,
	[BUID] [int] NOT NULL,
	[LName] [varchar](100) NULL,
	[FName] [varchar](100) NULL,
	[Phone] [datetime] NULL,
	[Zip] [datetime] NULL,
	[Email] [varchar](100) NULL,
	[TermedDate] [datetime] NULL,
	[HRStatusID] [int] NULL,
	[HRCurrStatusID] [int] NULL,
	[HRBU] [int] NULL,
	[CompanyID] [int] NULL,
	[BSPChannelID] [int] NULL,
	[BTChannelID] [int] NULL,
	[ValidationID] [int] NULL,
	[ChangeID] [int] NULL,
	[SecAnswerID] [int] NULL,
	[BankFIID] [varchar](100) NULL,
	[CmsChain] [varchar](100) NULL,
	[SalesID] [int] NULL,
	[RegionID] [int] NULL,
	[AddComments] [varchar](1000) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
	[Stale] [varchar](100) NULL,
	[ErrorMessage] [varchar](2000) NULL,
	[LastLogon] [datetime] NULL,
 CONSTRAINT [PK_USER] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[VW_RFIList]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE VIEW [dbo].[VW_RFIList]
AS
SELECT     DISTINCT    
R.ID,
R.RFITrackingID AS RFIID,
CASE WHEN ISNULL(R.[Description], '') = '' THEN A.[Description] + ' - ' + A.UAID + ' - ' + A.APMNumber ELSE R.[Description] END AS RFIName, 
A.Description AS ApplicationName, 
U.FName + ' ' + U.LName AS RFIOwner, RD.DueDate, RS.Description AS RFIStatus, CP.CampaignID, U.UserName AS UserId, RS.ID AS RFIStatusID, RA.ApplicationID
,ISNULL(BU.BUName,'') AS[BU]	,U.IsActive					 
FROM            dbo.RFI AS R INNER JOIN
                         dbo.RFICampaign AS RC ON RC.RFIID = R.ID INNER JOIN
                         dbo.Campaignperiod AS CP ON CP.CampaignID = RC.CampaignID INNER JOIN
                         dbo.RFIApplication AS RA ON RA.RFIID = R.ID INNER JOIN
                         dbo.[Application] AS A ON A.ID = RA.ApplicationID AND A.IsActive =1  JOIN
                         dbo.[User] AS U ON U.ID = RA.ApplicationOwnerUserid  INNER JOIN
						 dbo.[BU] AS BU ON BU.ID = R.BUID  AND BU.IsActive =1 INNER JOIN
                         dbo.RFIDueDt AS RD ON RD.RFIID = R.ID INNER JOIN
                         dbo.RFIStatusLog AS RSL ON RSL.RFIID = R.ID AND RSL.IsActive = 1 INNER JOIN
                         dbo.RFIStatus AS RS ON RS.ID = RSL.RFIStatusID AND RS.IsActive =1
GO
/****** Object:  Table [dbo].[Access]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Access](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_ACCESS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ACG]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACG](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_ACG] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ACGStatus]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACGStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_ACGSTATUS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Action]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Action](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ActionName] [varchar](10) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_ACTIONS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Appaccess]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Appaccess](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Desciption] [varchar](500) NULL,
 CONSTRAINT [PK_APPACCESS] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AppLog]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[LogDate] [datetime] NOT NULL,
	[ProcessInfo] [varchar](500) NOT NULL,
	[Text] [varchar](max) NULL,
	[UserID] [bigint] NOT NULL,
 CONSTRAINT [PK_AppLog] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Approval]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Approval](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Levels] [int] NULL,
	[Desciption] [varchar](10) NULL,
	[Show] [varchar](15) NULL,
 CONSTRAINT [PK_APPROVAL] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AppSubAccess]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppSubAccess](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AppAccessID] [int] NOT NULL,
	[Desciption] [varchar](500) NULL,
 CONSTRAINT [PK_APPSUBACCESS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AppSubSubAccess]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppSubSubAccess](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AppSubAccessID] [int] NULL,
	[Desciption] [varchar](500) NULL,
 CONSTRAINT [PK_APPSUBSUBACCESS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AppTemplate]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppTemplate](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[TemplateID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
	[IsDefault] [bit] NULL,
 CONSTRAINT [PK_AppTemplate] PRIMARY KEY CLUSTERED 
(
	[ApplicationID] ASC,
	[TemplateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AppUser]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppUser](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[ApplicationID] [int] NOT NULL,
 CONSTRAINT [PK_APPLICATIONOWNER] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[ApplicationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Asset]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Asset](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[AssetDetails] [varchar](500) NULL,
	[AssetNote] [varchar](1000) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
	[ErrorMessage] [varchar](2000) NULL,
 CONSTRAINT [PK_Asset] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AttestStatus]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AttestStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_ATTESTSTAUS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Bspchannel]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bspchannel](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ChannelName] [varchar](100) NULL,
 CONSTRAINT [PK_BSPCHANNEL] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Btchannel]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Btchannel](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ChannelName] [varchar](100) NULL,
 CONSTRAINT [PK_BTCHANNEL] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Campaign]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Campaign](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[FYID] [int] NOT NULL,
	[FQID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_CAMPAIGN] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Campaignmode]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Campaignmode](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CampaignID] [bigint] NOT NULL,
	[ModeID] [int] NOT NULL,
 CONSTRAINT [PK_CAMPAIGNMODE] PRIMARY KEY CLUSTERED 
(
	[CampaignID] ASC,
	[ModeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ChangeActionLog]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangeActionLog](
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [varchar](256) NOT NULL,
	[EventType] [varchar](50) NOT NULL,
	[ObjectName] [varchar](256) NOT NULL,
	[ObjectType] [varchar](25) NOT NULL,
	[SqlCommand] [varchar](max) NOT NULL,
	[EventDate] [datetime] NOT NULL,
	[LoginName] [varchar](256) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ChangeUser]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChangeUser](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RequestID] [bigint] NULL,
	[ChangeDate] [datetime] NULL,
	[UserID] [bigint] NOT NULL,
	[UserName] [varchar](30) NULL,
	[ActionID] [int] NULL,
	[LName] [varchar](100) NULL,
	[FName] [varchar](100) NULL,
	[Phone] [varchar](10) NULL,
	[Zip] [varchar](10) NULL,
	[Email] [varchar](100) NULL,
	[CompanyID] [int] NOT NULL,
	[BSPChannelID] [int] NULL,
	[BtTCannelID] [int] NULL,
	[ValidationID] [int] NULL,
	[AppSubAccessID] [int] NOT NULL,
	[AppSubSubAccessID] [int] NOT NULL,
 CONSTRAINT [PK_CHANGEUSER] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ClientTitle]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClientTitle](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Desciption] [varchar](100) NULL,
 CONSTRAINT [PK_CLIENTTITLE] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Clientuser]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Clientuser](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[LName] [varchar](100) NULL,
	[FName] [varchar](100) NULL,
	[Phone] [varchar](10) NULL,
	[Zip] [varchar](10) NULL,
	[ReportsTo] [bigint] NOT NULL,
 CONSTRAINT [PK_CLIENTUSER] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ClientUserTitle]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClientUserTitle](
	[UserID] [bigint] NOT NULL,
	[TitleID] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Company]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Company](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyAlias] [varchar](10) NULL,
	[CompanyName] [varchar](100) NULL,
 CONSTRAINT [PK_COMPANY] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DocStatus]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_DocStatus] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Document]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Document](
	[ID] [uniqueidentifier] NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[DocumentPath] [varchar](1000) NOT NULL,
	[DocumentTypeID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_DOCUMENT] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__Document__4EBBBAC98445E1D9] UNIQUE NONCLUSTERED 
(
	[Description] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DocumentDocStatus]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentDocStatus](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DocumentID] [uniqueidentifier] NOT NULL,
	[DocStatusID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_DocumentDocStatus] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DocumentType]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_DOCUMENTTYPE] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FinancialQuarter]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FinancialQuarter](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_FINANCIALQUARTER] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FinancialYear]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FinancialYear](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_FINANCIALYEAR] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FTAmpdocuments]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FTAmpdocuments] AS FILETABLE ON [PRIMARY] FILESTREAM_ON [FS]
WITH
(
FILETABLE_DIRECTORY = N'AMPQAFS', FILETABLE_COLLATE_FILENAME = SQL_Latin1_General_CP1_CI_AS
)
GO
/****** Object:  Table [dbo].[HRBusinessUnit]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRBusinessUnit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRBusinessUnit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRCenterJobTitle]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRCenterJobTitle](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRCenterJobTitle] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRCity]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRCity](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRCity] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRCountry]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRCountry](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[CountryISOCode] [varchar](500) NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRCountry] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRDivision]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRDivision](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRDivision] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRGroup]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRGroup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRGroup] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRJobFamily]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRJobFamily](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRJobFamily] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HROfficeTitle]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HROfficeTitle](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HROfficeTitle] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRSource]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRSource](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRSource] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRState]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRState](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NULL,
	[StateProvinceCode] [varchar](500) NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_HRState] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRStatus]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
 CONSTRAINT [PK_HRSTAUS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRUserLocation]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRUserLocation](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NULL,
	[AddressLine1] [varchar](500) NULL,
	[HRCountryId] [int] NULL,
	[HRStateId] [int] NULL,
	[HRCityId] [int] NULL,
	[PostalCode] [varchar](20) NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_HRUserLocation] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HRUserLocation_Bkp]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HRUserLocation_Bkp](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NULL,
	[AddressLine1] [varchar](500) NULL,
	[HRCountryId] [int] NULL,
	[HRStateId] [int] NULL,
	[HRCityId] [int] NULL,
	[PostalCode] [int] NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Menu]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Menu](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MenuName] [varchar](50) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[Sequence] [int] NOT NULL,
	[PMenuID] [int] NOT NULL,
	[URL] [varchar](1000) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_MENU] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MenuAction]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MenuAction](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Alias] [varchar](2) NOT NULL,
	[ActionName] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_MENUACTION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Mode]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mode](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_MODE] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Module]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Module](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ModuleName] [varchar](50) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[URL] [varchar](1000) NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_MODULE] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Permission]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Permission](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Alias] [char](1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_PERMISSION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Region]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Region](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Desciption] [varchar](10) NULL,
 CONSTRAINT [PK_REGION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RejectType]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RejectType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_RejectType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Request]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Request](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestNumber] [varchar](15) NOT NULL,
	[RequestDate] [datetime] NOT NULL,
	[ActionID] [int] NOT NULL,
	[CompanyID] [int] NOT NULL,
	[BSPChannelID] [int] NULL,
	[BTChannelID] [int] NULL,
	[LName] [varchar](100) NULL,
	[FName] [varchar](100) NOT NULL,
	[Phone] [varchar](10) NOT NULL,
	[Zip] [varchar](10) NOT NULL,
	[Email] [varchar](100) NULL,
	[ValidationID] [int] NULL,
	[SecAnswerID] [int] NOT NULL,
	[AppSubAccessID] [int] NOT NULL,
	[AppSubSubAccessID] [int] NOT NULL,
	[ApprovalID] [int] NOT NULL,
	[BankFID] [varchar](100) NULL,
	[CmsChain] [varchar](100) NULL,
	[SalesID] [int] NULL,
	[RegionID] [int] NULL,
	[AddComments] [varchar](1000) NULL,
 CONSTRAINT [PK_REQUEST] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RequestApproval]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RequestApproval](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RequestID] [bigint] NOT NULL,
	[ApproverID] [bigint] NOT NULL,
	[ApprovalID] [int] NOT NULL,
	[ApprovalDate] [datetime] NOT NULL,
 CONSTRAINT [PK_REQUESTAPPROVAL] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFDACG]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFDACG](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RFDID] [bigint] NOT NULL,
	[ACGID] [int] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
	[ACGStatus] [int] NULL,
 CONSTRAINT [PK_RFDACG] PRIMARY KEY CLUSTERED 
(
	[RFDID] ASC,
	[ACGID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIDataNeeded]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIDataNeeded](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_RFIDataNeeded] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIDelegate]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIDelegate](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RFIID] [bigint] NOT NULL,
	[Lname] [varchar](250) NOT NULL,
	[Fname] [varchar](250) NOT NULL,
	[LanId] [varchar](50) NULL,
	[EmailId] [varchar](50) NULL,
	[DelegateUserID] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_RFIDelegate] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIDocument]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIDocument](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RFIID] [bigint] NOT NULL,
	[DocumentID] [uniqueidentifier] NOT NULL,
	[AssignDt] [datetime] NOT NULL,
 CONSTRAINT [PK_RFIDOCUMENT] PRIMARY KEY CLUSTERED 
(
	[RFIID] ASC,
	[DocumentID] ASC,
	[AssignDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIDocumentUser]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIDocumentUser](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DocumentId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
 CONSTRAINT [PK_RFIDocumentUser] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFIGroup]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFIGroup](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_RFIGROUP] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Role] [varchar](100) NULL,
	[Description] [varchar](500) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
	[ErrorMessage] [varchar](2000) NULL,
 CONSTRAINT [PK_ROLE] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RolePermissionMenu]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RolePermissionMenu](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleID] [int] NOT NULL,
	[PermissionID] [int] NOT NULL,
	[MenuID] [int] NOT NULL,
	[MenuActionID] [int] NOT NULL,
 CONSTRAINT [PK_ROLEPERMISSIONMENU] PRIMARY KEY CLUSTERED 
(
	[RoleID] ASC,
	[PermissionID] ASC,
	[MenuActionID] ASC,
	[MenuID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SecAnswer]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SecAnswer](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SecQuestionID] [int] NOT NULL,
	[Desciption] [varchar](500) NULL,
 CONSTRAINT [PK_SECANSWER] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SecQuestion]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SecQuestion](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Desciption] [varchar](500) NULL,
 CONSTRAINT [PK_SECQUESTION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StagingRFI]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StagingRFI](
	[RFI ID] [nvarchar](50) NULL,
	[Status] [nvarchar](100) NULL,
	[Due Date] [nvarchar](20) NULL,
	[Campaign FY] [nvarchar](10) NULL,
	[Campaign Qtr] [nvarchar](10) NULL,
	[APM Number] [nvarchar](50) NULL,
	[Application Name] [nvarchar](500) NULL,
	[IT Application owner] [nvarchar](550) NULL,
	[Application Category] [nvarchar](100) NULL,
	[Data Needed] [nvarchar](50) NULL,
	[Business Owner] [nvarchar](500) NULL,
	[Delegate] [nvarchar](1000) NULL,
	[BusinessGroup] [nvarchar](200) NULL,
	[ACG] [nvarchar](50) NULL,
	[RejectedType] [nvarchar](50) NULL,
	[Generalcomments] [nvarchar](max) NULL,
	[ACGStatus] [nvarchar](100) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StagingWorkday]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StagingWorkday](
	[HREmployeeID] [varchar](10) NULL,
	[Legacy ID] [varchar](10) NULL,
	[HRFirstName] [varchar](50) NULL,
	[HRLastName] [varchar](50) NULL,
	[HRMiddleName] [varchar](50) NULL,
	[HRHireDate] [varchar](10) NULL,
	[HRJobFamily] [varchar](100) NULL,
	[HROfficeTitle] [varchar](100) NULL,
	[HRCenterJobTitle] [varchar](100) NULL,
	[HRSource] [varchar](100) NULL,
	[HRStatus] [varchar](20) NULL,
	[HRSupervisorID] [varchar](10) NULL,
	[HRSupervisorName] [varchar](100) NULL,
	[HRTermDateInitiated] [varchar](10) NULL,
	[HRTermDateEffective] [varchar](10) NULL,
	[HREeCategory] [varchar](10) NULL,
	[EmailAddress] [varchar](250) NULL,
	[Phone] [varchar](100) NULL,
	[PhoneBusinessExtension] [varchar](20) NULL,
	[PhoneMobile1] [varchar](20) NULL,
	[ADLogonName] [varchar](30) NULL,
	[GroupName] [varchar](50) NULL,
	[DivisionName] [varchar](50) NULL,
	[BusinessUnitName] [varchar](100) NULL,
	[LocationName] [varchar](100) NULL,
	[LocationAddress1] [varchar](200) NULL,
	[LocationCity] [varchar](100) NULL,
	[LocationStateProvince] [varchar](100) NULL,
	[LocationStateName] [varchar](100) NULL,
	[LocationPostalCode] [varchar](20) NULL,
	[LocationCountry] [varchar](100) NULL,
	[LocationISOCode] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Template]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Template](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](100) NOT NULL,
	[Details] [varchar](500) NULL,
	[DocumentTypeID] [int] NOT NULL,
	[DocumentData] [varchar](max) NOT NULL,
	[TemplateTypeID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_Template] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TemplateType]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TemplateType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [bigint] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_TemplateType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserAccess]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserAccess](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[ModuleID] [int] NOT NULL,
	[AccessID] [int] NULL,
	[AppSubAccessID] [int] NULL,
	[AppSubSubAccessID] [int] NULL,
 CONSTRAINT [PK_USERBACCESS] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserAsset]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserAsset](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[AssetID] [bigint] NOT NULL,
	[AssignDt] [datetime] NULL,
 CONSTRAINT [PK_USERASSET] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[AssetID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserListAppRole]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserListAppRole](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](100) NOT NULL,
	[AppName] [varchar](100) NULL,
	[RoleName] [varchar](100) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NULL,
	[CreatedDt] [datetime] NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_USERLISTAPPROLE] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserLogin]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserLogin](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[LoginAttmpt] [int] NOT NULL,
	[LogInDt] [datetime] NOT NULL,
	[LogOutDt] [datetime] NOT NULL,
	[IsLocked] [bit] NOT NULL,
 CONSTRAINT [PK_USERLOGIN] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[LogInDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserMenu]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserMenu](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[MenuID] [int] NOT NULL,
	[AssignDt] [datetime] NOT NULL,
 CONSTRAINT [PK_USERMENU] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[MenuID] ASC,
	[AssignDt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserMenuAction]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserMenuAction](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[MenuID] [int] NOT NULL,
	[MenuActionID] [int] NOT NULL,
 CONSTRAINT [PK_USERMENUACTION] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[MenuID] ASC,
	[MenuActionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserReportsTo]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserReportsTo](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[ReportsTo] [bigint] NOT NULL,
	[FromDt] [datetime] NOT NULL,
	[ToDt] [datetime] NOT NULL,
 CONSTRAINT [PK_USERREPORTSTO] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[ReportsTo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserRFI]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserRFI](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[RFIID] [bigint] NOT NULL,
	[AttestStatusID] [int] NULL,
	[AssignDt] [datetime] NOT NULL,
	[Reportto] [bigint] NULL,
	[UserListAppRoleId] [bigint] NULL,
 CONSTRAINT [PK_USERRFI] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[RFIID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserRole]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserRole](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [bigint] NOT NULL,
	[RoleID] [int] NOT NULL,
 CONSTRAINT [PK_USERBROLE] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[RoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Validation]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Validation](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Desciption] [varchar](100) NULL,
 CONSTRAINT [PK_VALIDATION] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WorkDay]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkDay](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[HREmployeeID] [int] NOT NULL,
	[LegacyID] [varchar](10) NULL,
	[HRFirstName] [varchar](100) NOT NULL,
	[HRLastName] [varchar](100) NOT NULL,
	[HRMiddleName] [varchar](50) NULL,
	[HRHireDate] [datetime] NULL,
	[HRJobFamilyId] [int] NULL,
	[HROfficeTitleId] [int] NULL,
	[HRCenterJobTitleId] [int] NULL,
	[HRSourceId] [int] NULL,
	[HRStatusId] [int] NULL,
	[HRSupervisorID] [int] NULL,
	[HRTermDateInitiated] [datetime] NULL,
	[HRTermDateEffective] [datetime] NULL,
	[HREeCategory] [varchar](10) NULL,
	[EmailAddress] [varchar](100) NULL,
	[Phone] [varchar](100) NULL,
	[PhoneBusinessExtension] [varchar](100) NULL,
	[PhoneMobile1] [varchar](100) NULL,
	[ADLogonName] [varchar](30) NULL,
	[GroupNameId] [int] NULL,
	[DivisionNameId] [int] NULL,
	[BusinessUnitNameId] [int] NULL,
	[HRLocationId] [int] NULL,
	[CreatedBy] [bigint] NOT NULL,
	[CreatedDt] [datetime] NOT NULL,
	[ModifiedBy] [bigint] NULL,
	[ModifiedDt] [datetime] NULL,
 CONSTRAINT [PK_workday] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Access] ADD  CONSTRAINT [DF_ACCESS_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ACG] ADD  CONSTRAINT [DF_ACG_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ACGStatus] ADD  CONSTRAINT [DF_ACGSTATUS_isactive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Action] ADD  CONSTRAINT [DF_ACTIONS_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Application] ADD  CONSTRAINT [DF_APPLICATION_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[AppTemplate] ADD  CONSTRAINT [DF_AppTemplate_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Asset] ADD  CONSTRAINT [DF_Asset_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[AttestStatus] ADD  CONSTRAINT [DF_ATTESTSTAUS_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BU] ADD  CONSTRAINT [DF_BU_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Campaign] ADD  CONSTRAINT [DF_CAMPAIGN_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Campaignmode] ADD  CONSTRAINT [DF_CAMPAIGNMODE_MODEID]  DEFAULT ((1)) FOR [ModeID]
GO
ALTER TABLE [dbo].[ChangeActionLog] ADD  CONSTRAINT [DF_EventsLog_EventDate]  DEFAULT (getdate()) FOR [EventDate]
GO
ALTER TABLE [dbo].[DocStatus] ADD  CONSTRAINT [DF_DocStatus_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Document] ADD  CONSTRAINT [DF_Document_ID]  DEFAULT (newid()) FOR [ID]
GO
ALTER TABLE [dbo].[Document] ADD  CONSTRAINT [DF_Document_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Document] ADD  CONSTRAINT [DF_Document_CreatedDt]  DEFAULT (getdate()) FOR [CreatedDt]
GO
ALTER TABLE [dbo].[DocumentDocStatus] ADD  CONSTRAINT [DF_DocumentDocStatus_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[FinancialQuarter] ADD  CONSTRAINT [DF_FINANCIALQUARTER_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[FinancialYear] ADD  CONSTRAINT [DF_FINANCIALYEAR_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[MenuAction] ADD  CONSTRAINT [DF_MENUACTION_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Mode] ADD  CONSTRAINT [DF_MODE_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Permission] ADD  CONSTRAINT [DF_PERMISSION_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RejectType] ADD  CONSTRAINT [DF_RejectType_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RFI] ADD  CONSTRAINT [DF_RFI_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RFIDataNeeded] ADD  CONSTRAINT [DF_RFIDataNeeded_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RFIDelegate] ADD  CONSTRAINT [DF_RFIDelegate_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RFIGroup] ADD  CONSTRAINT [DF_RFIGROUP_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RFIStatus] ADD  CONSTRAINT [DF_RFISTAUS_isactive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RFIStatusLog] ADD  CONSTRAINT [DF_RFIStatusLog_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Role] ADD  CONSTRAINT [DF_ROLE_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Template] ADD  CONSTRAINT [DF_Template_IsActive_1]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[TemplateType] ADD  CONSTRAINT [DF_TemplateType_IsActive_1]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_USER_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserListAppRole] ADD  CONSTRAINT [DF_USERLISTAPPROLE_ISACTIVE]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserLogin] ADD  CONSTRAINT [DF_USERLOGIN_ISLOCKED]  DEFAULT ((0)) FOR [IsLocked]
GO
ALTER TABLE [dbo].[AppSubAccess]  WITH CHECK ADD  CONSTRAINT [FK_APPSUBACCESS_APPACCESS] FOREIGN KEY([AppAccessID])
REFERENCES [dbo].[Appaccess] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AppSubAccess] CHECK CONSTRAINT [FK_APPSUBACCESS_APPACCESS]
GO
ALTER TABLE [dbo].[AppSubSubAccess]  WITH CHECK ADD  CONSTRAINT [FK_APPSUBSUBACCESS_APPSUBACCESS] FOREIGN KEY([AppSubAccessID])
REFERENCES [dbo].[AppSubAccess] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AppSubSubAccess] CHECK CONSTRAINT [FK_APPSUBSUBACCESS_APPSUBACCESS]
GO
ALTER TABLE [dbo].[AppTemplate]  WITH CHECK ADD  CONSTRAINT [FK_AppTemplate_APPLICATION] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AppTemplate] CHECK CONSTRAINT [FK_AppTemplate_APPLICATION]
GO
ALTER TABLE [dbo].[AppTemplate]  WITH CHECK ADD  CONSTRAINT [FK_AppTemplate_Template] FOREIGN KEY([TemplateID])
REFERENCES [dbo].[Template] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AppTemplate] CHECK CONSTRAINT [FK_AppTemplate_Template]
GO
ALTER TABLE [dbo].[AppUser]  WITH CHECK ADD  CONSTRAINT [FK_APPLICATIONOWNER_APPLICATION] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AppUser] CHECK CONSTRAINT [FK_APPLICATIONOWNER_APPLICATION]
GO
ALTER TABLE [dbo].[AppUser]  WITH CHECK ADD  CONSTRAINT [FK_APPLICATIONOWNER_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AppUser] CHECK CONSTRAINT [FK_APPLICATIONOWNER_USER]
GO
ALTER TABLE [dbo].[Campaign]  WITH CHECK ADD  CONSTRAINT [FK_CAMPAIGN_FINANCIALQUARTER] FOREIGN KEY([FQID])
REFERENCES [dbo].[FinancialQuarter] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Campaign] CHECK CONSTRAINT [FK_CAMPAIGN_FINANCIALQUARTER]
GO
ALTER TABLE [dbo].[Campaign]  WITH CHECK ADD  CONSTRAINT [FK_CAMPAIGN_FINANCIALYEAR] FOREIGN KEY([FYID])
REFERENCES [dbo].[FinancialYear] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Campaign] CHECK CONSTRAINT [FK_CAMPAIGN_FINANCIALYEAR]
GO
ALTER TABLE [dbo].[Campaignmode]  WITH CHECK ADD  CONSTRAINT [FK_CAMPAIGNMODE_CAMPAIGN] FOREIGN KEY([CampaignID])
REFERENCES [dbo].[Campaign] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Campaignmode] CHECK CONSTRAINT [FK_CAMPAIGNMODE_CAMPAIGN]
GO
ALTER TABLE [dbo].[Campaignmode]  WITH CHECK ADD  CONSTRAINT [FK_CAMPAIGNMODE_MODE] FOREIGN KEY([ModeID])
REFERENCES [dbo].[Mode] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Campaignmode] CHECK CONSTRAINT [FK_CAMPAIGNMODE_MODE]
GO
ALTER TABLE [dbo].[Campaignperiod]  WITH CHECK ADD  CONSTRAINT [FK_CAMPAIGNPERIOD_CAMPAIGN] FOREIGN KEY([CampaignID])
REFERENCES [dbo].[Campaign] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Campaignperiod] CHECK CONSTRAINT [FK_CAMPAIGNPERIOD_CAMPAIGN]
GO
ALTER TABLE [dbo].[ChangeUser]  WITH CHECK ADD  CONSTRAINT [FK_CHANGEUSER_ACTIONS] FOREIGN KEY([ActionID])
REFERENCES [dbo].[Action] ([ID])
GO
ALTER TABLE [dbo].[ChangeUser] CHECK CONSTRAINT [FK_CHANGEUSER_ACTIONS]
GO
ALTER TABLE [dbo].[ChangeUser]  WITH CHECK ADD  CONSTRAINT [FK_CHANGEUSER_REQUEST] FOREIGN KEY([RequestID])
REFERENCES [dbo].[Request] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ChangeUser] CHECK CONSTRAINT [FK_CHANGEUSER_REQUEST]
GO
ALTER TABLE [dbo].[ClientUserTitle]  WITH CHECK ADD  CONSTRAINT [FK_CLIENTUSERTITLE_CLIENTTITLE] FOREIGN KEY([TitleID])
REFERENCES [dbo].[ClientTitle] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ClientUserTitle] CHECK CONSTRAINT [FK_CLIENTUSERTITLE_CLIENTTITLE]
GO
ALTER TABLE [dbo].[ClientUserTitle]  WITH CHECK ADD  CONSTRAINT [FK_CLIENTUSERTITLE_CLIENTUSER] FOREIGN KEY([UserID])
REFERENCES [dbo].[Clientuser] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ClientUserTitle] CHECK CONSTRAINT [FK_CLIENTUSERTITLE_CLIENTUSER]
GO
ALTER TABLE [dbo].[Document]  WITH CHECK ADD  CONSTRAINT [FK_DOCUMENT_DOCUMENTTYPE2] FOREIGN KEY([DocumentTypeID])
REFERENCES [dbo].[DocumentType] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Document] CHECK CONSTRAINT [FK_DOCUMENT_DOCUMENTTYPE2]
GO
ALTER TABLE [dbo].[Document]  WITH CHECK ADD  CONSTRAINT [FK_Document_FTAmpdocuments] FOREIGN KEY([ID])
REFERENCES [dbo].[FTAmpdocuments] ([stream_id])
GO
ALTER TABLE [dbo].[Document] CHECK CONSTRAINT [FK_Document_FTAmpdocuments]
GO
ALTER TABLE [dbo].[DocumentDocStatus]  WITH CHECK ADD  CONSTRAINT [FK_DocumentDocStatus_DocStatus] FOREIGN KEY([DocStatusID])
REFERENCES [dbo].[DocStatus] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentDocStatus] CHECK CONSTRAINT [FK_DocumentDocStatus_DocStatus]
GO
ALTER TABLE [dbo].[DocumentDocStatus]  WITH CHECK ADD  CONSTRAINT [FK_DocumentDocStatus_Document] FOREIGN KEY([DocumentID])
REFERENCES [dbo].[Document] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentDocStatus] CHECK CONSTRAINT [FK_DocumentDocStatus_Document]
GO
ALTER TABLE [dbo].[HRUserLocation]  WITH CHECK ADD  CONSTRAINT [FK_HRUserLocation_HRCity1] FOREIGN KEY([HRCityId])
REFERENCES [dbo].[HRCity] ([ID])
GO
ALTER TABLE [dbo].[HRUserLocation] CHECK CONSTRAINT [FK_HRUserLocation_HRCity1]
GO
ALTER TABLE [dbo].[HRUserLocation]  WITH CHECK ADD  CONSTRAINT [FK_HRUserLocation_HRCountry1] FOREIGN KEY([HRCountryId])
REFERENCES [dbo].[HRCountry] ([ID])
GO
ALTER TABLE [dbo].[HRUserLocation] CHECK CONSTRAINT [FK_HRUserLocation_HRCountry1]
GO
ALTER TABLE [dbo].[HRUserLocation]  WITH CHECK ADD  CONSTRAINT [FK_HRUserLocation_HRState1] FOREIGN KEY([HRStateId])
REFERENCES [dbo].[HRState] ([ID])
GO
ALTER TABLE [dbo].[HRUserLocation] CHECK CONSTRAINT [FK_HRUserLocation_HRState1]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_ACTIONS] FOREIGN KEY([ActionID])
REFERENCES [dbo].[Action] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_ACTIONS]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_APPROVAL] FOREIGN KEY([ApprovalID])
REFERENCES [dbo].[Approval] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_APPROVAL]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_BSPCHANNEL] FOREIGN KEY([BSPChannelID])
REFERENCES [dbo].[Bspchannel] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_BSPCHANNEL]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_BTCHANNEL] FOREIGN KEY([BTChannelID])
REFERENCES [dbo].[Btchannel] ([ID])
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_BTCHANNEL]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_COMPANY] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Company] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_COMPANY]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_REGION] FOREIGN KEY([RegionID])
REFERENCES [dbo].[Region] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_REGION]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_SECANSWER] FOREIGN KEY([SecAnswerID])
REFERENCES [dbo].[SecAnswer] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_SECANSWER]
GO
ALTER TABLE [dbo].[Request]  WITH CHECK ADD  CONSTRAINT [FK_REQUEST_VALIDATION] FOREIGN KEY([ValidationID])
REFERENCES [dbo].[Validation] ([ID])
GO
ALTER TABLE [dbo].[Request] CHECK CONSTRAINT [FK_REQUEST_VALIDATION]
GO
ALTER TABLE [dbo].[RequestApproval]  WITH CHECK ADD  CONSTRAINT [FK_RequestApproval_Approval] FOREIGN KEY([ApprovalID])
REFERENCES [dbo].[Approval] ([ID])
GO
ALTER TABLE [dbo].[RequestApproval] CHECK CONSTRAINT [FK_RequestApproval_Approval]
GO
ALTER TABLE [dbo].[RequestApproval]  WITH CHECK ADD  CONSTRAINT [FK_REQUESTAPPROVAL_CLIENTUSER] FOREIGN KEY([ApproverID])
REFERENCES [dbo].[Clientuser] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RequestApproval] CHECK CONSTRAINT [FK_REQUESTAPPROVAL_CLIENTUSER]
GO
ALTER TABLE [dbo].[RequestApproval]  WITH CHECK ADD  CONSTRAINT [FK_RequestApproval_Request] FOREIGN KEY([RequestID])
REFERENCES [dbo].[Request] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RequestApproval] CHECK CONSTRAINT [FK_RequestApproval_Request]
GO
ALTER TABLE [dbo].[RFDACG]  WITH CHECK ADD  CONSTRAINT [DF_RFDACG_ACG] FOREIGN KEY([ACGID])
REFERENCES [dbo].[ACG] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFDACG] CHECK CONSTRAINT [DF_RFDACG_ACG]
GO
ALTER TABLE [dbo].[RFDACG]  WITH CHECK ADD  CONSTRAINT [DF_RFIACG_RFI] FOREIGN KEY([RFDID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFDACG] CHECK CONSTRAINT [DF_RFIACG_RFI]
GO
ALTER TABLE [dbo].[RFDACG]  WITH CHECK ADD  CONSTRAINT [FK_RFDACG_ACGSTATUS] FOREIGN KEY([ACGStatus])
REFERENCES [dbo].[ACGStatus] ([ID])
GO
ALTER TABLE [dbo].[RFDACG] CHECK CONSTRAINT [FK_RFDACG_ACGSTATUS]
GO
ALTER TABLE [dbo].[RFI]  WITH CHECK ADD  CONSTRAINT [FK_RFI_RFIGROUP] FOREIGN KEY([RFIGroupID])
REFERENCES [dbo].[RFIGroup] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFI] CHECK CONSTRAINT [FK_RFI_RFIGROUP]
GO
ALTER TABLE [dbo].[RFIApplication]  WITH CHECK ADD  CONSTRAINT [FK_RFIAPPLICATION_APPLICATION] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[Application] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFIApplication] CHECK CONSTRAINT [FK_RFIAPPLICATION_APPLICATION]
GO
ALTER TABLE [dbo].[RFIApplication]  WITH CHECK ADD  CONSTRAINT [FK_RFIAPPLICATION_RFI] FOREIGN KEY([RFIID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFIApplication] CHECK CONSTRAINT [FK_RFIAPPLICATION_RFI]
GO
ALTER TABLE [dbo].[RFIApplication]  WITH CHECK ADD  CONSTRAINT [FK_RFIAPPOwner_User] FOREIGN KEY([ApplicationOwnerUserid])
REFERENCES [dbo].[User] ([ID])
GO
ALTER TABLE [dbo].[RFIApplication] CHECK CONSTRAINT [FK_RFIAPPOwner_User]
GO
ALTER TABLE [dbo].[RFICampaign]  WITH CHECK ADD  CONSTRAINT [FK_RFICAMPAIGN_CAMPAIGN] FOREIGN KEY([CampaignID])
REFERENCES [dbo].[Campaign] ([ID])
GO
ALTER TABLE [dbo].[RFICampaign] CHECK CONSTRAINT [FK_RFICAMPAIGN_CAMPAIGN]
GO
ALTER TABLE [dbo].[RFICampaign]  WITH CHECK ADD  CONSTRAINT [FK_RFICAMPAIGN_CAMPAIGN1] FOREIGN KEY([CampaignID])
REFERENCES [dbo].[Campaign] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFICampaign] CHECK CONSTRAINT [FK_RFICAMPAIGN_CAMPAIGN1]
GO
ALTER TABLE [dbo].[RFICampaign]  WITH CHECK ADD  CONSTRAINT [FK_RFICAMPAIGN_RFI] FOREIGN KEY([RFIID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFICampaign] CHECK CONSTRAINT [FK_RFICAMPAIGN_RFI]
GO
ALTER TABLE [dbo].[RFIDelegate]  WITH CHECK ADD  CONSTRAINT [FK_RFIDELEGATE_RFI] FOREIGN KEY([RFIID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFIDelegate] CHECK CONSTRAINT [FK_RFIDELEGATE_RFI]
GO
ALTER TABLE [dbo].[RFIDocument]  WITH CHECK ADD  CONSTRAINT [FK_RFIDOCUMENT_DOCUMENT] FOREIGN KEY([DocumentID])
REFERENCES [dbo].[Document] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFIDocument] CHECK CONSTRAINT [FK_RFIDOCUMENT_DOCUMENT]
GO
ALTER TABLE [dbo].[RFIDocument]  WITH CHECK ADD  CONSTRAINT [FK_RFIDOCUMENT_RFI] FOREIGN KEY([RFIID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFIDocument] CHECK CONSTRAINT [FK_RFIDOCUMENT_RFI]
GO
ALTER TABLE [dbo].[RFIDueDt]  WITH CHECK ADD  CONSTRAINT [FK_RFIDUEDT_RFI] FOREIGN KEY([RFIID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFIDueDt] CHECK CONSTRAINT [FK_RFIDUEDT_RFI]
GO
ALTER TABLE [dbo].[RFIStatusLog]  WITH CHECK ADD  CONSTRAINT [FK_RFISTATUSLOG_RFI1] FOREIGN KEY([RFIID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RFIStatusLog] CHECK CONSTRAINT [FK_RFISTATUSLOG_RFI1]
GO
ALTER TABLE [dbo].[RFIStatusLog]  WITH CHECK ADD  CONSTRAINT [FK_RFISTATUSLOG_RFISTATUS] FOREIGN KEY([RFIStatusID])
REFERENCES [dbo].[RFIStatus] ([ID])
GO
ALTER TABLE [dbo].[RFIStatusLog] CHECK CONSTRAINT [FK_RFISTATUSLOG_RFISTATUS]
GO
ALTER TABLE [dbo].[RolePermissionMenu]  WITH CHECK ADD  CONSTRAINT [FK_RolePermissionMenu_Menu] FOREIGN KEY([MenuID])
REFERENCES [dbo].[Menu] ([ID])
GO
ALTER TABLE [dbo].[RolePermissionMenu] CHECK CONSTRAINT [FK_RolePermissionMenu_Menu]
GO
ALTER TABLE [dbo].[RolePermissionMenu]  WITH CHECK ADD  CONSTRAINT [FK_ROLEPERMISSIONMENU_PERMISSION] FOREIGN KEY([PermissionID])
REFERENCES [dbo].[Permission] ([ID])
GO
ALTER TABLE [dbo].[RolePermissionMenu] CHECK CONSTRAINT [FK_ROLEPERMISSIONMENU_PERMISSION]
GO
ALTER TABLE [dbo].[RolePermissionMenu]  WITH CHECK ADD  CONSTRAINT [FK_RolePermissionMenu_Role] FOREIGN KEY([RoleID])
REFERENCES [dbo].[Role] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RolePermissionMenu] CHECK CONSTRAINT [FK_RolePermissionMenu_Role]
GO
ALTER TABLE [dbo].[SecAnswer]  WITH CHECK ADD  CONSTRAINT [FK_SECANSWER_SECQUESTION] FOREIGN KEY([SecQuestionID])
REFERENCES [dbo].[SecQuestion] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SecAnswer] CHECK CONSTRAINT [FK_SECANSWER_SECQUESTION]
GO
ALTER TABLE [dbo].[Template]  WITH CHECK ADD  CONSTRAINT [FK_Template_DOCUMENTTYPE] FOREIGN KEY([DocumentTypeID])
REFERENCES [dbo].[DocumentType] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Template] CHECK CONSTRAINT [FK_Template_DOCUMENTTYPE]
GO
ALTER TABLE [dbo].[Template]  WITH CHECK ADD  CONSTRAINT [FK_Template_TemplateType] FOREIGN KEY([TemplateTypeID])
REFERENCES [dbo].[TemplateType] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Template] CHECK CONSTRAINT [FK_Template_TemplateType]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_USER_BSPCHANNEL] FOREIGN KEY([BSPChannelID])
REFERENCES [dbo].[Bspchannel] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_USER_BSPCHANNEL]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_USER_BTCHANNEL] FOREIGN KEY([BTChannelID])
REFERENCES [dbo].[Btchannel] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_USER_BTCHANNEL]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_User_BU] FOREIGN KEY([BUID])
REFERENCES [dbo].[BU] ([ID])
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_User_BU]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_User_BU1] FOREIGN KEY([HRBU])
REFERENCES [dbo].[BU] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_User_BU1]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_USER_COMPANY] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Company] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_USER_COMPANY]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_USER_VALIDATION] FOREIGN KEY([ValidationID])
REFERENCES [dbo].[Validation] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_USER_VALIDATION]
GO
ALTER TABLE [dbo].[UserAccess]  WITH CHECK ADD  CONSTRAINT [FK_UserAccess_Access] FOREIGN KEY([AccessID])
REFERENCES [dbo].[Access] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserAccess] CHECK CONSTRAINT [FK_UserAccess_Access]
GO
ALTER TABLE [dbo].[UserAccess]  WITH CHECK ADD  CONSTRAINT [FK_UserAccess_AppSubAccess] FOREIGN KEY([AppSubAccessID])
REFERENCES [dbo].[AppSubAccess] ([ID])
GO
ALTER TABLE [dbo].[UserAccess] CHECK CONSTRAINT [FK_UserAccess_AppSubAccess]
GO
ALTER TABLE [dbo].[UserAccess]  WITH CHECK ADD  CONSTRAINT [FK_UserAccess_AppSubSubAccess] FOREIGN KEY([AppSubSubAccessID])
REFERENCES [dbo].[AppSubSubAccess] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserAccess] CHECK CONSTRAINT [FK_UserAccess_AppSubSubAccess]
GO
ALTER TABLE [dbo].[UserAccess]  WITH CHECK ADD  CONSTRAINT [FK_UserAccess_Module] FOREIGN KEY([ModuleID])
REFERENCES [dbo].[Module] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserAccess] CHECK CONSTRAINT [FK_UserAccess_Module]
GO
ALTER TABLE [dbo].[UserAccess]  WITH CHECK ADD  CONSTRAINT [FK_USERACCESS_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserAccess] CHECK CONSTRAINT [FK_USERACCESS_USER]
GO
ALTER TABLE [dbo].[UserAsset]  WITH CHECK ADD  CONSTRAINT [FK_USERASSET_ASSET] FOREIGN KEY([AssetID])
REFERENCES [dbo].[Asset] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserAsset] CHECK CONSTRAINT [FK_USERASSET_ASSET]
GO
ALTER TABLE [dbo].[UserAsset]  WITH CHECK ADD  CONSTRAINT [FK_USERASSET_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserAsset] CHECK CONSTRAINT [FK_USERASSET_USER]
GO
ALTER TABLE [dbo].[UserLogin]  WITH CHECK ADD  CONSTRAINT [FK_USERLOGIN_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserLogin] CHECK CONSTRAINT [FK_USERLOGIN_USER]
GO
ALTER TABLE [dbo].[UserMenu]  WITH CHECK ADD  CONSTRAINT [FK_USERMENU_MENU] FOREIGN KEY([MenuID])
REFERENCES [dbo].[Menu] ([ID])
GO
ALTER TABLE [dbo].[UserMenu] CHECK CONSTRAINT [FK_USERMENU_MENU]
GO
ALTER TABLE [dbo].[UserMenu]  WITH CHECK ADD  CONSTRAINT [FK_USERMENU_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserMenu] CHECK CONSTRAINT [FK_USERMENU_USER]
GO
ALTER TABLE [dbo].[UserMenuAction]  WITH CHECK ADD  CONSTRAINT [FK_USERMENUACTION_MENU] FOREIGN KEY([MenuID])
REFERENCES [dbo].[Menu] ([ID])
GO
ALTER TABLE [dbo].[UserMenuAction] CHECK CONSTRAINT [FK_USERMENUACTION_MENU]
GO
ALTER TABLE [dbo].[UserMenuAction]  WITH CHECK ADD  CONSTRAINT [FK_UserMenuAction_MenuAction] FOREIGN KEY([MenuActionID])
REFERENCES [dbo].[MenuAction] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserMenuAction] CHECK CONSTRAINT [FK_UserMenuAction_MenuAction]
GO
ALTER TABLE [dbo].[UserMenuAction]  WITH CHECK ADD  CONSTRAINT [FK_USERMENUACTION_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserMenuAction] CHECK CONSTRAINT [FK_USERMENUACTION_USER]
GO
ALTER TABLE [dbo].[UserReportsTo]  WITH CHECK ADD  CONSTRAINT [FK_USERREPORTSTO_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserReportsTo] CHECK CONSTRAINT [FK_USERREPORTSTO_USER]
GO
ALTER TABLE [dbo].[UserRFI]  WITH CHECK ADD  CONSTRAINT [FK_UserRFI_AttestStatus] FOREIGN KEY([AttestStatusID])
REFERENCES [dbo].[AttestStatus] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserRFI] CHECK CONSTRAINT [FK_UserRFI_AttestStatus]
GO
ALTER TABLE [dbo].[UserRFI]  WITH CHECK ADD  CONSTRAINT [FK_UserRFI_RFI] FOREIGN KEY([RFIID])
REFERENCES [dbo].[RFI] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserRFI] CHECK CONSTRAINT [FK_UserRFI_RFI]
GO
ALTER TABLE [dbo].[UserRFI]  WITH CHECK ADD  CONSTRAINT [FK_USERRFI_RoleID] FOREIGN KEY([UserListAppRoleId])
REFERENCES [dbo].[UserListAppRole] ([ID])
GO
ALTER TABLE [dbo].[UserRFI] CHECK CONSTRAINT [FK_USERRFI_RoleID]
GO
ALTER TABLE [dbo].[UserRFI]  WITH CHECK ADD  CONSTRAINT [FK_UserRFI_User] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserRFI] CHECK CONSTRAINT [FK_UserRFI_User]
GO
ALTER TABLE [dbo].[UserRole]  WITH CHECK ADD  CONSTRAINT [FK_USERROLE_USER] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserRole] CHECK CONSTRAINT [FK_USERROLE_USER]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRBusinessUnit] FOREIGN KEY([BusinessUnitNameId])
REFERENCES [dbo].[HRBusinessUnit] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRBusinessUnit]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRCenterJobTitle] FOREIGN KEY([HRCenterJobTitleId])
REFERENCES [dbo].[HRCenterJobTitle] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRCenterJobTitle]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRDivision] FOREIGN KEY([DivisionNameId])
REFERENCES [dbo].[HRDivision] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRDivision]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRGroup] FOREIGN KEY([GroupNameId])
REFERENCES [dbo].[HRGroup] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRGroup]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRJobFamily] FOREIGN KEY([HRJobFamilyId])
REFERENCES [dbo].[HRJobFamily] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRJobFamily]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HROfficeTitle] FOREIGN KEY([HROfficeTitleId])
REFERENCES [dbo].[HROfficeTitle] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HROfficeTitle]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRSource] FOREIGN KEY([HRSourceId])
REFERENCES [dbo].[HRSource] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRSource]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRStatus] FOREIGN KEY([HRStatusId])
REFERENCES [dbo].[HRStatus] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRStatus]
GO
ALTER TABLE [dbo].[WorkDay]  WITH CHECK ADD  CONSTRAINT [FK_WorkDay_HRUserLocation] FOREIGN KEY([HRLocationId])
REFERENCES [dbo].[HRUserLocation] ([ID])
GO
ALTER TABLE [dbo].[WorkDay] CHECK CONSTRAINT [FK_WorkDay_HRUserLocation]
GO
/****** Object:  StoredProcedure [dbo].[CreateUpdateTemplateData]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[CreateUpdateTemplateData](
@TemplateId int,
@ApplicationId int,
@Description varchar(max),
@Details varchar(max),
@TemplateTypeId int,
@DocumentTypeId int,
@DocumentData varchar(max),
@UserId int,
@IsDefault bit = NULL,
@ReturnVal int = 0 OUTPUT
)
AS
BEGIN

BEGIN TRY
BEGIN TRANSACTION

	IF (@TemplateId = 0)
	BEGIN
		INSERT INTO TEMPLATE(Description, Details, DocumentTypeID, DocumentData, TemplateTypeID, IsActive, CreatedBy, CreatedDt) 
		VALUES (@Description, @Details, @DocumentTypeId, @DocumentData, @TemplateTypeId, 1, @UserId, GETDATE())

		Set @TemplateId = Scope_Identity()

		INSERT INTO AppTemplate (ApplicationID, TemplateID, IsActive, CreatedBy, CreatedDt, IsDefault)
		VALUES (@ApplicationId, @TemplateId, 1, @UserId, GETDATE(), @IsDefault)

		IF (@IsDefault = 1)
		BEGIN
			UPDATE AppTemplate set ISDEFAULT = 0 WHERE ApplicationID = @ApplicationId
			UPDATE AppTemplate SET ISDEFAULT = 1 WHERE ApplicationID = @ApplicationId AND TemplateID = @TemplateId
		END
		ELSE
		BEGIN
			UPDATE AppTemplate SET ISDEFAULT = 0 WHERE ApplicationID = @ApplicationId AND TemplateID = @TemplateId
		END
	END
	ELSE
	BEGIN
		UPDATE Template SET
		Description = @Description,
		Details = @Details,
		DocumentTypeID = @DocumentTypeId,
		TemplateTypeId = @TemplateTypeId,
		DocumentData = @DocumentData,
		ModifiedBy = @UserId,
		ModifiedDt = GETDATE()
		WHERE ID = @TemplateId;

		IF (@IsDefault = 1)
		BEGIN
			UPDATE AppTemplate set ISDEFAULT = 0 WHERE ApplicationID = @ApplicationId
			UPDATE AppTemplate SET ISDEFAULT = 1 WHERE ApplicationID = @ApplicationId AND TemplateID = @TemplateId
		END
		ELSE
		BEGIN
			UPDATE AppTemplate SET ISDEFAULT = 0 
			WHERE ApplicationID = @ApplicationId 
			AND TemplateID = @TemplateId
		END
		
	END

	SET @ReturnVal = @TemplateId

	COMMIT TRANSACTION

	--SELECT tt.id from template tt left join AppTemplate apt on apt.templateid = tt.id
	-- apt.applicationid = @ApplicationId and tt.Description = @Description
	   
	END TRY
	-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
SELECT 
@ErrorMessage = ERROR_MESSAGE(), 
@ErrorSeverity = ERROR_SEVERITY(), 
@ErrorState = ERROR_STATE(); 
 
-- Use RAISERROR inside the CATCH block to return error 
-- information about the original error that caused 
-- execution to jump to the CATCH block. 
RAISERROR (
@ErrorMessage, -- Message text. 
 @ErrorSeverity, -- Severity. 
 @ErrorState -- State. 
); 
END CATCH;
-- Exception Handling Section END

END

GO
/****** Object:  StoredProcedure [dbo].[DeleteRFDsforDelegate]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ========================================================
-- Author: Hari
-- Create Date: 12/18/2021
-- Description: dbo.DeleteRFDsforDelegate
-- Purpose :delete RFDDelegate user 
--EXEC DeleteRFDsforDelegate 789
 =========================================================

*/

CREATE    PROCEDURE [dbo].[DeleteRFDsforDelegate]
@DelegateUserId BIGINT
AS
BEGIN

BEGIN TRY

IF EXISTS(SELECT 1 FROM RFIDelegate WHERE DelegateUserID = @DelegateUserId AND IsActive = 1)
BEGIN

UPDATE RFIDelegate

SET IsActive = 0

WHERE DelegateUserID =@DelegateUserId

END

END TRY

-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END

END
GO
/****** Object:  StoredProcedure [dbo].[DeleteRFIDocument]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO





/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 02/08/2022
-- Description: dbo.DeleteRFIDocument
-- Purpose : DELETE Uploaded RFIDocument@rfistatusid
-- EXEC DeleteRFIDocument 38,'E089D764-1C33-45E4-9B77-550179AD7B8B'
 =========================================================

*/

CREATE      PROC [dbo].[DeleteRFIDocument] 
(
@rfiid bigint,
@documentid uniqueidentifier

)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY
BEGIN TRANSACTION

IF (SELECT COUNT(*) FROM dbo.RFIDocument RD WHERE RD.RFIID =@rfiid)=1
BEGIN

--Single Document

--check uploded document success

			IF (Select count(1) FROM dbo.DocumentDocStatus DDS 
					INNER JOIN dbo.DocStatus DS ON DDS.DocStatusID =DS.ID  AND DDS.IsActive =1  AND DS.[Description] ='Success'
					WHERE DDS.DocumentID =@documentid )>0

					BEGIN						

						--DELETE UserAsset
						DELETE FROM dbo.UserAsset WHERE UserId IN (SELECT UserID FROM dbo.UserRFI WHERE RFIID =@rfiid) 

						--DELETE UserRole
						DELETE FROM dbo.UserRole WHERE UserId IN (SELECT UserID FROM dbo.UserRFI WHERE RFIID =@rfiid)

						---DELETE User
						DELETE FROM dbo.[User] WHERE Id IN (SELECT UserID FROM dbo.UserRFI WHERE RFIID =@rfiid) 

						---DELETE USERRFI
						DELETE FROM dbo.UserRFI WHERE RFIID =@rfiid

						--DELETE RFIDocumentUser
						DELETE FROM Dbo.RFIDocumentUser WHERE DocumentId in ( SELECT ID FROM dbo.RFIDocument WHERE RFIID=@rfiid  AND DocumentID =@documentid )

					END 
END
ELSE 
BEGIN 
   
--Multiple document
--Check user dependency in other doc and delete user

     
					IF (SELECT COUNT(*) FROM dbo.DocumentDocStatus DDS 
					INNER JOIN dbo.DocStatus DS ON DDS.DocStatusID =DS.ID  AND DDS.IsActive =1  AND DS.[Description] ='Success'
					WHERE DDS.DocumentID =@documentid )>0

					BEGIN

					DROP TABLE IF EXISTS #DELETEUser
					DROP TABLE IF EXISTS #OTHDOCUser

					SELECT USERID INTO #DELETEUser FROM dbo.RFIDocumentUser  WHERE DocumentId in ( SELECT ID FROM dbo.RFIDocument WHERE RFIID=@rfiid  AND DocumentID =@documentid ) 
					SELECT USERID INTO #OTHDOCUser FROM dbo.RFIDocumentUser  WHERE DocumentId in ( SELECT ID FROM dbo.RFIDocument WHERE RFIID=@rfiid  AND DocumentID <> @documentid ) 
					---SELECT * FROM #DELETEUser

					DELETE FROM #DELETEUser WHERE USERID IN(SELECT USERID FROM #OTHDOCUser)

				
						--DELETE UserAsset
						DELETE  FROM dbo.UserAsset WHERE UserId IN (SELECT UserID FROM dbo.UserRFI WHERE RFIID =@rfiid AND UserID IN(SELECT USERID FROM #DELETEUser)) 

						--DELETE UserRole
						DELETE FROM dbo.UserRole WHERE UserId IN (SELECT UserID FROM dbo.UserRFI WHERE RFIID =@rfiid AND UserID IN(SELECT USERID FROM #DELETEUser))

						---DELETE User
						DELETE FROM dbo.[User] WHERE Id IN (SELECT UserID FROM dbo.UserRFI WHERE RFIID =@rfiid AND UserID IN(SELECT USERID FROM #DELETEUser)) 

						---DELETE USERRFI
						DELETE FROM dbo.UserRFI WHERE RFIID =@rfiid AND  UserID IN(SELECT USERID FROM #DELETEUser)

						--DELETE RFIDocumentUser

						DELETE FROM Dbo.RFIDocumentUser WHERE DocumentId in ( SELECT ID FROM dbo.RFIDocument WHERE RFIID=@rfiid  AND DocumentID =@documentid )
					END 
END


--DELETE DocDocumentStatus

DELETE FROM dbo.DocumentDocStatus WHERE DocumentID =@documentid 

--DELETE RFIDocument

DELETE FROM dbo.RFIDocument  WHERE DocumentID =@documentid 


--DELETE Document

DELETE FROM dbo.Document WHERE ID=@documentid 



COMMIT TRANSACTION
END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION;
	SELECT 
	@ErrorMessage = 'DELETERFIDocument-proc' +ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
--return 1
END
GO
/****** Object:  StoredProcedure [dbo].[GetApplicationList]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

/* ========================================================
-- Author: Eswara
-- Create Date: 11/10/2021
-- Description: GetRfiListbyBU

--EXEC [GetApplicationList] 'Brandon Harris','',0
--EXEC [GetApplicationList] 'jay','','08-27-2021'

 ========================================================*/

Create   proc [dbo].[GetApplicationList]
(
@FirstName varchar(250) =null,
@LastName varchar(250) =null
)
AS
BEGIN-- Executable Section BEGIN 
BEGIN TRY
-- List Application Names 
select app.ID, app.[Description], case when exists (select 1 from UserLogin ul where ul.UserID = u.ID) then 1 else 0 end as Statuses
from [Application] app, RFIApplication ra, [User] u
where app.IsActive = 1 and ra.ApplicationID = app.ID
and u.IsActive = 1 and ra.ApplicationOwnerUserid = u.ID
and u.FName = @FirstName and u.LName = @LastName
union
select app.ID, app.[Description], 0
from [Application] app inner join RFIApplication ra
on ra.ApplicationID = app.ID
left join [User] u
on u.IsActive = 1 and ra.ApplicationOwnerUserid = u.ID
where app.IsActive = 1 and (ra.ApplicationOwnerUserid is null or u.ID is null)

END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END

GO
/****** Object:  StoredProcedure [dbo].[GetCurrentRFIList]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCurrentRFIList] 
AS
BEGIN-- Executable Section BEGIN 

declare @currentcampaignid bigint
BEGIN TRY
declare @Rfdid bigint
 --get currentcampaignid based on campaigndate else getdate
SELECT @currentcampaignid=[CampaignID]  FROM  [dbo].[Campaignperiod]WHERE Convert(Datetime,getdate(),101) 
between convert(date,convert(varchar(10),[StartDt],101)) AND
convert(date,convert(varchar(10),[EndDt]+1,101))


SELECT ID,
RFIID,
RFIName,
RFIStatus,
RFIOwner
FROM VW_RFIList WHERE CampaignID=@currentcampaignid 
AND RFIStatus IN('Complete/Certification started','Submitted/Pending Acceptance')


END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  StoredProcedure [dbo].[GetCurrentUserListDetails]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

	
/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 10/21/2021
-- Description: GetCurrentUserListDetails
-- Purpose :Get current campaign userlist for ACG approval
--EXEC GetCurrentUserListDetails 178
 =========================================================

*/


CREATE     PROC [dbo].[GetCurrentUserListDetails] 
@Rfiid bigint
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY

declare @currentcampaignid bigint

SELECT @currentcampaignid=[CampaignID]  FROM  [dbo].[Campaignperiod]WHERE Convert(Datetime,getdate(),101) 
between convert(date,convert(varchar(10),[StartDt],101)) AND
convert(date,convert(varchar(10),[EndDt]+1,101))


print @currentcampaignid
--Get Formated UserList based on RFDID


	SELECT DISTINCT   
CAST(C.ID as varchar(20))+'Q'+ FORMAT(getDate(),'yy')+' '+RGP.[Description] AS  [ReviewID],
ISNULL(B.BUName,'') AS [BU],
AP.APMNumber AS [UAID],
ISNULL(A.[Description],'') AS [Asset] ,
ISNULL(A.AssetDetails,'') AS [AssetDetail],
ISNULL(A.AssetNote,'') AS [AssetNotes],
ISNULL(U.FName,'') AS [FirstName],
ISNULL(U.LName,'') AS [LastName],
ISNULL(U.UserName,'') AS [UserId],
ISNULL(U.EmpID,'') As [EmployeeID],
ISNULL(RO.[Description],'') AS [Role],
'' AS LastLogin
FROM
dbo.UserRFI UR
		INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive =1
		INNER JOIN dbo.BU B ON B.ID=U.BUID AND B.IsActive =1
		LEFT JOIN [dbo].[UserAsset] UA ON UA.UserID=U.ID
		LEFT JOIN [dbo].[Asset] A ON A.ID=UA.AssetID AND A.IsActive =1
		INNER JOIN [dbo].[UserRole] UR1 ON UR1.UserId=U.ID
		LEFT JOIN [dbo].[Role] RO ON RO.Id=UR1.Roleid AND RO.IsActive =1
		INNER JOIN [dbo].RFIStatusLog RSL ON RSL.RFIID =UR.RFIID  AND RSL.IsActive =1
		INNER JOIN [dbo].RFIStatus RS ON RS.ID =RSL.RFIStatusID AND RS.IsActive =1 AND RS.[Description] IN('Complete/Certification started')
		INNER JOIN [dbo].RFICampaign RC ON RC.RFIID =UR.RFIID 
		INNER JOIN [dbo].Campaign C ON C.ID =RC.CampaignID AND C.IsActive =1
		INNER JOIN [dbo].[RFIApplication] RFA  ON  RFA.RFIID =UR.RFIID 
		INNER JOIN [dbo].[RFI] R ON R.Id=UR.RFIID 
		INNER JOIN [dbo].[RFIGroup] RGP ON RGP.ID=R.RFIGroupID  
		INNER JOIN [dbo].[Application] AP ON AP.ID =RFA.ApplicationID AND AP.IsActive =1	
	WHERE C.ID=@currentcampaignid AND UR.RFIID=@Rfiid AND U.ID NOT IN (SELECT USERID FROM dbo.UserLogin)


	
END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  StoredProcedure [dbo].[GetDetailsByQuarter]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 9/14/2021
-- Description: [GetDetailsByQuarter]
EXEC [GetDetailsByQuarter] 'ALL User'
EXEC [GetDetailsByQuarter] 'All Status'
EXEC [GetDetailsByQuarter] 'Open'
EXEC [GetDetailsByQuarter] 'ACG Completed'
EXEC [GetDetailsByQuarter] 'Missed RFI'
 =========================================================
*/

--select *from dbo.[user]
CREATE proc [dbo].[GetDetailsByQuarter] 
(
@dashboard varchar(50) 
)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY

declare @currentcampaignid bigint
 --get currentcampaignid based on campaigndate else getdate
SELECT @currentcampaignid=[CampaignID]  FROM  [dbo].[Campaignperiod]WHERE Convert(Datetime,getdate(),101) between
convert(datetime,convert(varchar(10),[StartDt],101)) AND
convert(datetime,convert(varchar(10),[EndDt]+1,101))

IF (UPPER(@dashboard)=UPPER('ALL User'))
BEGIN

--Total Certifications by quater
SELECT FiscalYear,FiscalQuarter,[User Only] AS [UserOnly],[Admin Only] As [AdminOnly],[User and Admin] As [UserandAdmin],[No User] as [NoUser]
	FROM (
			SELECT ISNULL(RD.[Description],'No User') AS DataNeeded 
			,FY.[Description] AS [FiscalYear]
			,FQ.[Description] As [FiscalQuarter]
		
			From 
			[dbo].RFI  R
			INNER JOIN [dbo].[RFICampaign] RC ON RC.RFIID=R.ID
			INNER JOIN [dbo].[Campaign] C ON C.ID=RC.CampaignID AND  C.ID =@currentcampaignid			 
			INNER JOIN [dbo].RFIApplication RA ON RA.RFIID =R.ID
			INNER JOIN [dbo].[Application] A ON A.ID=RA.ApplicationID  AND A.IsActive =1
			INNER JOIN [dbo].[RFIStatusLog] RSL ON RSL.RFIID=R.ID AND RSL.ISACTIVE=1
			INNER JOIN [dbo].[RFIStatus] RS ON RS.ID=RSL.RFIStatusID   AND RS.IsActive =1
			LEFT JOIN  [dbo].[RFIDataNeeded] RD ON RD.ID=R.DataNeeded
			INNER JOIN [dbo].[FinancialYear] FY ON FY.ID=C.FYID
			INNER JOIN [dbo].[FinancialQuarter] FQ ON FQ.ID=C.FQID) A
			PIVOT
			(
			COUNT(DataNeeded)
			For [DataNeeded]
			IN ([User Only],[Admin Only],[User and Admin],[No User])
			) AS PivotTable



END


IF (UPPER(@dashboard)=UPPER('ALL Status'))
BEGIN
SELECT FiscalYear,FiscalQuarter,[Open],[Submitted/Pending Acceptance] As[SubmittedorPendingAcceptance],[Returned],[Accepted/Processing] as [AcceptedorProcessing],[Closed/Incomplete] as [ClosedorIncomplete],[Complete/Certification started] as[CompleteorCertificationStarted]
	FROM (
			SELECT RS.[Description]  AS RFIStatus 
			,FY.[Description] AS [FiscalYear]
			,FQ.[Description] As [FiscalQuarter]
		
			From 
			[dbo].RFI  R
			INNER JOIN [dbo].[RFICampaign] RC ON RC.RFIID=R.ID
			INNER JOIN [dbo].[Campaign] C ON C.ID=RC.CampaignID AND  C.ID =@currentcampaignid			 
			INNER JOIN [dbo].RFIApplication RA ON RA.RFIID =R.ID
			INNER JOIN [dbo].[Application] A ON A.ID=RA.ApplicationID  AND A.IsActive =1
			INNER JOIN [dbo].[RFIStatusLog] RSL ON RSL.RFIID=R.ID AND RSL.ISACTIVE=1
			INNER JOIN [dbo].[RFIStatus] RS ON RS.ID=RSL.RFIStatusID   AND RS.IsActive =1
			LEFT JOIN  [dbo].[RFIDataNeeded] RD ON RD.ID=R.DataNeeded
			INNER JOIN [dbo].[FinancialYear] FY ON FY.ID=C.FYID
			INNER JOIN [dbo].[FinancialQuarter] FQ ON FQ.ID=C.FQID) A
			PIVOT
			(
			COUNT(RFIStatus)
			For RFIStatus
			IN ([Open],[Submitted/Pending Acceptance],[Returned],[Accepted/Processing] ,[Complete/Certification started],[Closed/Incomplete])
			) AS PivotTable
END


IF (UPPER(@dashboard)=UPPER('Open'))
BEGIN
SELECT FiscalYear,FiscalQuarter,[User Only] AS [UserOnly],[Admin Only] As [AdminOnly],[User and Admin] As [UserandAdmin],[No User] as [NoUser]
	FROM (
			SELECT ISNULL(RD.[Description],'No User') AS DataNeeded 
			,FY.[Description] AS [FiscalYear]
			,FQ.[Description] As [FiscalQuarter]
		
			From 
			[dbo].RFI  R
			INNER JOIN [dbo].[RFICampaign] RC ON RC.RFIID=R.ID
			INNER JOIN [dbo].[Campaign] C ON C.ID=RC.CampaignID AND  C.ID =@currentcampaignid			 
			INNER JOIN [dbo].RFIApplication RA ON RA.RFIID =R.ID
			INNER JOIN [dbo].[Application] A ON A.ID=RA.ApplicationID  AND A.IsActive =1
			INNER JOIN [dbo].[RFIStatusLog] RSL ON RSL.RFIID=R.ID AND RSL.ISACTIVE=1
			INNER JOIN [dbo].[RFIStatus] RS ON RS.ID=RSL.RFIStatusID   AND RS.IsActive =1 AND RS.[Description] ='Open'
			LEFT JOIN  [dbo].[RFIDataNeeded] RD ON RD.ID=R.DataNeeded
			INNER JOIN [dbo].[FinancialYear] FY ON FY.ID=C.FYID
			INNER JOIN [dbo].[FinancialQuarter] FQ ON FQ.ID=C.FQID) A
			PIVOT
			(
			COUNT(DataNeeded)
			For [DataNeeded]
			IN ([User Only],[Admin Only],[User and Admin],[No User])
			) AS PivotTable

END

IF (UPPER(@dashboard)=UPPER('ACG Completed'))
BEGIN
--Total Certifications ACG Completed byquater
SELECT FiscalYear,FiscalQuarter,[User Only] AS [UserOnly],[Admin Only] As [AdminOnly],[User and Admin] As [UserandAdmin],[No User] as [NoUser]
	FROM (
			SELECT ISNULL(RD.[Description],'No User') AS DataNeeded 
			,FY.[Description] AS [FiscalYear]
			,FQ.[Description] As [FiscalQuarter]
			From 
			[dbo].RFI  R
			INNER JOIN [dbo].[RFICampaign] RC ON RC.RFIID=R.ID
			INNER JOIN [dbo].[Campaign] C ON C.ID=RC.CampaignID AND  C.ID =@currentcampaignid			 
			INNER JOIN [dbo].RFIApplication RA ON RA.RFIID =R.ID 
				INNER JOIN [dbo].[Application] A ON A.ID=RA.ApplicationID  AND A.IsActive =1
			INNER JOIN [dbo].[RFIStatusLog] RSL ON RSL.RFIID=R.ID AND RSL.ISACTIVE=1 
			INNER JOIN [dbo].[RFIStatus] RS ON RS.ID=RSL.RFIStatusID AND RS.[Description]='Complete/Certification started'  AND RS.IsActive =1
			LEFT JOIN  [dbo].[RFIDataNeeded] RD ON RD.ID=R.DataNeeded
			INNER JOIN [dbo].[FinancialYear] FY ON FY.ID=C.FYID
			INNER JOIN [dbo].[FinancialQuarter] FQ ON FQ.ID=C.FQID) A
			PIVOT
			(
			COUNT(DataNeeded)
			For [DataNeeded]
			IN ([User Only],[Admin Only],[User and Admin],[No User])
			) AS PivotTable

			
END


IF (UPPER(@dashboard)=UPPER('Missed RFI'))
BEGIN
--Total Certifications Missed byquater
SELECT FiscalYear,FiscalQuarter,[User Only] AS [UserOnly],[Admin Only] As [AdminOnly],[User and Admin] As [UserandAdmin],[No User] as [NoUser]
	FROM (
			SELECT ISNULL(RD.[Description],'No User') AS DataNeeded 
			,FY.[Description] AS [FiscalYear]
			,FQ.[Description] As [FiscalQuarter]
			From 
			[dbo].RFI  R
			INNER JOIN [dbo].[RFICampaign] RC ON RC.RFIID=R.ID
			INNER JOIN [dbo].[Campaign] C ON C.ID=RC.CampaignID AND  C.ID =@currentcampaignid			 
			INNER JOIN [dbo].RFIApplication RA ON RA.RFIID =R.ID
				INNER JOIN [dbo].[Application] A ON A.ID=RA.ApplicationID  AND A.IsActive =1
			INNER JOIN [dbo].[RFIStatusLog] RSL ON RSL.RFIID=R.ID AND RSL.ISACTIVE=1 
			INNER JOIN [dbo].[RFIStatus] RS ON RS.ID=RSL.RFIStatusID AND RS.[Description]='Returned' AND RS.IsActive =1
			LEFT JOIN  [dbo].[RFIDataNeeded] RD ON RD.ID=R.DataNeeded
			INNER JOIN [dbo].[FinancialYear] FY ON FY.ID=C.FYID
			INNER JOIN [dbo].[FinancialQuarter] FQ ON FQ.ID=C.FQID) A
			PIVOT
			(
			COUNT(DataNeeded)
			For [DataNeeded]
			IN ([User Only],[Admin Only],[User and Admin],[No User])
			) AS PivotTable
			END

END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  StoredProcedure [dbo].[GetRawFileDetails]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ========================================================    
Author: TUSHAR CHAKRABORTY    
Create Date: 23/09/2021    
Description: Get RFI ,Template and  File details for extracting Raw data  from uploded file
Modified By:    krrishnajayanthi.v 
Modified Date:    10/11/2021
Reason:    default values to userdetails to avoid duplicate data
Dependencies:    
[RFI],[RFIStatusLog],[RFIStatus],[UserRFI],[User],[UserRole],[Role],[AppUser],[Application],    
[RFIDocument],[Document],[DocumentType],[Template],[TemplateType],[FTAmpdocuments]    
Output list: RFIID,     
RFITrackingID,     
RFIName,     
RFIOwser,     
RFIStatus,     
UserName,     
roleid,     
role,     
ApplicationName,     
ApplicationID,     
TemplateID,     
TemplateTypeId,     
Description,     
DocumentTypeId,     
documentData,    
RFDFileName,     
FileType,     
StreamId,     
FileStream    
Executable Command: EXEC GetRawFileDetails;    
=========================================================    
*/    
CREATE PROCEDURE [dbo].[GetRawFileDetails]   
AS    
BEGIN    
SET NOCOUNT ON;    
--Declaration Section BEGIN     
--Declaration Section END    
-- Executable Section BEGIN     
BEGIN TRY    


SELECT    DISTINCT  
	RF.ID RFIID,    
	RF.[Description] RFIName,    
	RF.[RFITrackingID] RFITrackingID  ,
	RS.[Description] RFIStatus,
	D.CreatedBy as UserID,
	'' AS UserName,
	'' AS  RFIOwser   ,
	0 as RoleID,
	''as  RoleName  ,
	'' as ApplicationName , 
	AT.ApplicationID  as ApplicationID,
	--0  as ApplicationID,
	D.Description RFDFileName    ,
	T.ID TemplateID,    
	T.Description TemplateName,    
	TT.ID TemplateTypeId,    
	t.DocumentData,    
	AFT.file_type FileType,    
	AFT.stream_id as StreamId,    
	AFT.file_stream as FileStream,  
	RFD.DocumentID DocumentID  
	,DS.[Description] As [DocStatus]
FROM [dbo].[RFI] RF    
INNER JOIN [dbo].[RFIStatusLog] RSL    
ON RF.ID = RSL.RFIID    AND RSL.IsActive = 1    
INNER JOIN [dbo].[RFIStatus] RS    
ON RSL.RFIStatusID = RS.ID    and RS.Description  in('Open','Returned') AND RS.IsActive =1


AND RS.IsActive = 1    
Left JOIN ( [dbo].[UserRFI] URF 
			INNER JOIN [dbo].[User] U  ON U.ID =URF.UserID AND U.IsActive =1
			LEFT JOIN [dbo].[UserRole] UR  ON  UR.UserID    = U.ID
			INNER JOIN [dbo].[Role] R   ON UR.RoleID = R.ID  AND R.ISACTIVE=1   )     ON  URF.RFIID    =RF.ID 

Left JOIN [dbo].[RFIDocument] RFD    ON  RFD.RFIID    =RF.ID 
INNER JOIN [dbo].[Document] D    ON RFD.DocumentID = D.ID    
INNER JOIN [dbo].[DocumentType] DT    ON D.DocumentTypeID = DT.ID    
INNER JOIN [dbo].[DocumentDocStatus] DDS ON DDS.DocumentID=D.ID  AND DDS.ISActive=1
INNER JOIN [dbo].[DocStatus] DS ON DS.ID=DDS.DocStatusID  AND DS.[Description] IN('Uploaded','In Progress')
INNER JOIN [dbo].[RFIApplication] RFA ON RFA.RFIID=RF.ID
INNER JOIN [dbo].[Application] A    ON RFA.ApplicationID = A.ID AND A.IsActive =1
INNER JOIN [dbo].[AppTemplate] AT    ON AT.ApplicationID = A.ID   AND AT.ISDEFAULT=1
INNER JOIN [dbo].[Template] T    ON AT.TemplateID=T.ID
--AND T.IsActive = 1    
INNER JOIN [dbo].[TemplateType] TT    ON T.TemplateTypeID = TT.ID    
INNER JOIN [dbo].[FTAmpdocuments] AFT    ON D.ID = AFT.stream_id 
WHERE RF.IsActive = 1  
ORDER BY    
	RFIName,    
	RFDFileName; 


END TRY    
-- Executable Section END    
-- Exception Handling Section BEGIN    
BEGIN CATCH    
DECLARE @ErrorMessage NVARCHAR(4000);     
DECLARE @ErrorSeverity INT;     
DECLARE @ErrorState INT;     
SELECT     
@ErrorMessage = ERROR_MESSAGE(),     
@ErrorSeverity = ERROR_SEVERITY(),     
@ErrorState = ERROR_STATE();     
     
-- Use RAISERROR inside the CATCH block to return error     
-- information about the original error that caused     
-- execution to jump to the CATCH block.    
RAISERROR (    
@ErrorMessage, -- Message text.     
 @ErrorSeverity, -- Severity.     
 @ErrorState -- State.     
);     
END CATCH;    
-- Exception Handling Section END    
END; 
GO
/****** Object:  StoredProcedure [dbo].[GetRFIDetails]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 9/06/2021
-- Description: GetRFIDetails
-- Purpose :Get each  RFI information by passing MAP RFID or AMP TrackingId
--EXEC GetRFIDetails 2
 =========================================================

*/


CREATE PROC [dbo].[GetRFIDetails] 
(
 @rfid VARCHAR(500)
)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY

declare @currentcampaignid bigint


 --get currentcampaignid based on campaigndate else getdate
SELECT @currentcampaignid=[CampaignID]  FROM  [dbo].[Campaignperiod]WHERE Convert(Datetime,getdate(),101)  between
convert(date,convert(varchar(10),[StartDt],101)) AND
convert(date,convert(varchar(10),[EndDt]+1,101))





SELECT DISTINCT R.ID,
--heading
	R.RFITrackingID AS RFDDescription  ,--R.[Description]
	--ISNULL(ACG.[Description],'') AS [ACG],
	--ISNULL(AGS.[Description],'') AS [ACG DataRequestStatus],
--quater/Year
	FQ.Description As [Quater],
	FY.Description As [Year],
	ISNULL(RG.[Description],'') As [ApplicationCategory],
	ISNULL(RDN.[Description],'') as [DataNeeded],
--General Information
	R.RFITrackingID AS [CertID],---R.[Description]  
	--SUBSTRING(R.RFITrackingID ,CHARINDEX('-',R.RFITrackingID)+1, LEN(R.RFITrackingID ))  AS [TrackingID],
	ISNULL(A.[Description],'') AS [ApplicationName],
	ISNULL(A.APMNumber,'') AS [ApplicationNumber],
	ISNULL(R.BusinessOwner,'') AS [BusinessOwner],
	CASE WHEN ISNULL(U.FName,'')!=''  THEN ISNULL(ISNULL(U.LName,'') +','+ISNULL(U.FName,''),'') ELSE ISNULL(U.LName,'')		
		END 	AS [ITApplicationOwner],
	R.CreatedDt AS [CreatedDate],
--	DATEDIFF(Day,getdate(),RD.DueDate) AS[Noofdaysduedate],
	RD.DueDate AS [CertDuedate],
	ISNULL(RS.[Description],'') As [DataRequestStatus],
	--RS.[Description] As [DataRequestSubStatus],
	ISNULL(RT.[Description],'')  AS  [RejectedType],
	ISNULL(RSL.Comments,'')  As [GeneralComments],  
	--Delegate
--'Bakshi, Rana F36B6U8 |Test, Delegate ' AS [Delegate]
   ISNULL(dbo.UdfGetDelegate(RFD.RFIID),'') AS [Delegate]
   ,ISNULL(B.BUName,'') AS [BusinessUnit]
	--,ISNULL(AG.[Description],'') AS [ACG]  [ACG], [ACG DataRequestStatus],[Noofdaysduedate]
FROM  
	[dbo].[RFI] R
	INNER JOIN [dbo].[RFICampaign] RC ON RC.RFIID=R.ID
	INNER JOIN [dbo].[Campaign] C ON C.ID=RC.CampaignID
	INNER JOIN [dbo].[FinancialYear] FY ON FY.ID=C.FYID
	INNER JOIN [dbo].[FinancialQuarter]  FQ ON FQ.ID=C.FQID
	INNER JOIN [dbo].[RFIApplication] RA ON RA.RFIID=R.ID
	INNER JOIN [dbo].[Application]A ON A.ID=RA.ApplicationID AND A.IsActive=1	
	LEFT JOIN [dbo].[RFIDueDt] RD ON RD.RFIID =R.ID
	INNER JOIN [dbo].[RFIStatusLog] RSL ON RSL.[RFIID]=R.ID AND RSL.IsActive=1
	INNER JOIN [dbo].[RFIStatus] RS ON RS.ID =RSL.[RFIStatusID] AND RS.IsActive=1
	LEFT JOIN [dbo].[User] U ON U.ID=RA.ApplicationOwnerUserid
	LEFT JOIN [dbo].[RFIGroup] RG ON RG.ID=R.RFIGroupID AND RG.IsActive=1
	LEFT JOIN [dbo].[RFIDelegate] RFD ON RFD.RFIID=R.ID
	LEFT JOIN [dbo].[RFIDataNeeded] RDN ON RDN.ID=R.[DataNeeded] AND RDN.IsActive=1
	LEFT JOIN [BU] B ON B.Id=R.BUID	AND B.IsActive=1
	LEFT JOIN dbo.RejectType RT ON RT.ID =RSL. RejectTypeid
	LEFT JOIN dbo.[RFDACG] RACG ON RACG.RFDID =R.ID 
	LEFT JOIN [dbo].[ACG] ACG ON ACG.ID=RACG.ACGID 
	LEFT JOIN [dbo].[ACGStatus] AGS ON AGS.Id=RACG.ACGStatus 
	WHERE R.ID=@rfid AND CampaignID=@currentcampaignid



END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  StoredProcedure [dbo].[GetRFIDocuments]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE     PROCEDURE [dbo].[GetRFIDocuments]
(  
@rfiId BIGINT  
)  
AS  
BEGIN-- Executable Section BEGIN   
  
BEGIN TRY  
   
 SELECT   
   d.ID as DocumentId,  
   LEFT(d.[Description], len(d.[Description]) - charindex('_', reverse(d.[Description]) + '_')) AS  RFDFileName,  
   ftd.file_type as FileType,  
   LEFT(d.[Description], len(d.[Description]) - charindex('_', reverse(d.[Description]) + '_')) + '.' + ftd.file_type  AS  [FileName],  
   Convert(nvarchar(50), Convert(bigint, ftd.cached_file_size) / 1048576.0 ) as FileSize, -- Here Converting Bytes to MB  
   CASE WHEN ds.[Description] = 'Uploaded' THEN 'Uploaded - Processing in Progress' ELSE ds.[Description] END as [FileStatus]  
 FROM Document d  
 INNER JOIN RFIDocument rd ON d.ID = rd.DocumentID  
 INNER JOIN FTAmpdocuments ftd  ON d.ID =ftd.stream_id  
 INNER JOIN DocumentDocStatus dds ON d.ID = dds.DocumentID and dds.ISActive=1  
 INNER JOIN DocStatus ds ON dds.DocStatusID = ds.ID AND ds.IsActive =1  
 WHERE rd.RFIID = @rfiId  
 ORDER BY d.CreatedDt DESC;  
   
  
END TRY  
-- Executable Section END  
-- Exception Handling Section BEGIN  
BEGIN CATCH  
DECLARE @ErrorMessage NVARCHAR(4000);   
DECLARE @ErrorSeverity INT;   
DECLARE @ErrorState INT;   
   
 IF @@TRANCOUNT > 0  
  
 SELECT   
 @ErrorMessage = ERROR_MESSAGE(),   
 @ErrorSeverity = ERROR_SEVERITY(),   
 @ErrorState = ERROR_STATE();   
   
 -- Use RAISERROR inside the CATCH block to return error   
 -- information about the original error that caused   
 -- execution to jump to the CATCH block.   
 RAISERROR (  
 @ErrorMessage, -- Message text.   
  @ErrorSeverity, -- Severity.   
  @ErrorState -- State.   
 );   
END CATCH;  
-- Exception Handling Section END  
END  
GO
/****** Object:  StoredProcedure [dbo].[GetRFIList]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 8/20/2021
-- Modifued Date"9/13/2021
-- Description: GetRFIList
--EXEC [GetRFIList] 'vrentala','RFDDelegate','2021-08-24 10:14:12.550'
--EXEC [GetRFIList] 'snagpal','ACG','2021-08-24 10:14:12.550'
--EXEC  [GetRFIList] 'viverma','ApplicationOwner','2021-08-24 10:14:12.550'
 =========================================================
*/

--select *from dbo.[user]
CREATE   proc [dbo].[GetRFIList] 
(
@AMPUserid varchar(250),
@Role varchar(250), 
@CampaignDate Varchar(50) ---23/8/2021
)
AS
BEGIN-- Executable Section BEGIN 

declare @currentcampaignid bigint
BEGIN TRY
declare @Rfdid bigint
 --get currentcampaignid based on campaigndate else getdate

SELECT @currentcampaignid=[CampaignID] FROM [dbo].[Campaignperiod]WHERE Convert(Datetime,isnull(@CampaignDate,getdate()),101)
between convert(datetime,convert(varchar(10),[StartDt],101)) AND convert(datetime,convert(varchar(10),[EndDt],101))
--get RFI List based on Role

IF (UPPER(@role)=UPPER('ApplicationOwner'))
BEGIN

SELECT ID,
RFIID,
RFIName, 
ApplicationName,
RFIOwner,
DueDate,
RFIStatus,
ApplicationId,
BU

FROM VW_RFIList WHERE UserId=ltrim(rtrim(@AMPUserid)) AND CampaignID=@currentcampaignid

END

IF(UPPER(@role)=UPPER('RFDDelegate'))
BEGIN
SELECT ID,
RFIID,
RFIName,
ApplicationName,
RFIOwner,
DueDate,
RFIStatus,
ApplicationId,
BU

FROM VW_RFIList WHERE CampaignID=@currentcampaignid AND ID IN (select RFIID from dbo.RFIDelegate WHERE LanId=ltrim(rtrim(@AMPUserid)))

END


IF(UPPER(@role)=UPPER('ACGMember'))
BEGIN
SELECT ID,
RFIID,
RFIName,
ApplicationName,
RFIOwner,
DueDate,
RFIStatus,
CampaignID,
ApplicationId,
BU
FROM VW_RFIList WHERE CampaignID=@currentcampaignid

END


END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  StoredProcedure [dbo].[GetRFIListbySearch]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 8/20/2021
-- Description: GetRFIListbySearch

--EXEC [GetRFIListbySearch] 'Brandon Harris','',0,null
--EXEC [GetRFIListbySearch] 'jay','',2,'08-27-2021'
--EXEC [GetRFIListbySearch] 'jay','',0,'08-27-2021'
--EXEC [GetRFIListbySearch] '','',0,null
--EXEC [GetRFIListbySearch] '','08/29/2021',0,null

 ========================================================*/
CREATE proc [dbo].[GetRFIListbySearch] 
(
@appownerid varchar(250) =null,
@DueDate varchar(50) =null,
@RFIStatus int =null ,
@CampaignDate Varchar(50) =null
)
AS
BEGIN-- Executable Section BEGIN 

declare @currentcampaignid bigint
declare @mainquery varchar(max)


BEGIN TRY

 --get currentcampaignid based on campaigndate else getdate
SELECT @currentcampaignid=[CampaignID]  FROM  [dbo].[Campaignperiod]WHERE Convert(datetime,isnull(@CampaignDate,GETDATE()),101)  
		between convert(date,convert(varchar(10),[StartDt],101)) AND
convert(date,convert(varchar(10),[EndDt]+1,101))

	
--get data based on search criteria

SET @mainquery=N'
SELECT 
ID,
RFIID,
RFIName,
RFIOwner,
ApplicationName,
DueDate,
RFIStatus,
ApplicationId,
BU
FROM VW_RFIList WHERE [CampaignID]='+ cast(@currentcampaignid as varchar)

--add serach filter
IF ISNULL(@appownerid,'')!='' 
SET  @mainquery=@mainquery + ' AND RFIOwner LIKE '+ '''%' + @appownerid  +'%''';
IF ISNULL(@RFIStatus,0)!=0
SET  @mainquery=@mainquery + ' AND RFIStatusID =' + cast(@RFIStatus as varchar) ;
IF ISNULL(@DueDate,'')!=''
SET  @mainquery=@mainquery + ' AND DueDate=' + ''''+cast(@DueDate as varchar) +'''';


EXEC(@mainquery)


END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  StoredProcedure [dbo].[GetRFIListforDelegate]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


/* ========================================================
-- Author: 
-- Create Date:
-- Description: 
-- Purpose :
--EXEC [dbo].[GetRFIListforDelegate] '11',null
--EXEC [dbo].[GetRFIListforDelegate] 55,52
--EXEC [dbo].[GetRFIListforDelegate] '67138',0
 -========================================================

*/


CREATE     PROC [dbo].[GetRFIListforDelegate] 
(
@Appownerid varchar(50),
@delegateid bigint NULL
)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY

declare @currentcampaignid bigint

SELECT @currentcampaignid=[CampaignID]  FROM  [dbo].[Campaignperiod]WHERE Convert(datetime,GETDATE(),101)  
		between convert(date,convert(varchar(10),[StartDt],101)) AND
convert(date,convert(varchar(10),[EndDt]+1,101))


IF ISNULL(@delegateid,0) =0
BEGIN
SELECT DISTINCT 
R.ID,
R.RFITrackingID AS RFITracking,RA.ApplicationOwnerUserid ,U.FName +' ' +U.LName as[ApplicationOwner]
FROM dbo.[Application] A 
JOIN dbo.[RFIApplication] RA ON RA.ApplicationID=A.ID
JOIN dbo.[User]  U ON U.ID =RA.ApplicationOwnerUserid AND U.IsActive =1
JOIN dbo.RFI R ON R.ID=RA.RFIID 
JOIN dbo.RFICampaign AS RC ON RC.RFIID = R.ID AND RC.CampaignID =@currentcampaignid 
WHERE RA.ApplicationOwnerUserid IN ( select  cast([value] as bigint) as ID from STRING_SPLIT (@Appownerid, ',') )
END


IF ((isnull(@delegateid,0)>0) and (@Appownerid<>'0'))
BEGIN

SELECT DISTINCT
R.ID,
R.RFITrackingID AS RFITracking,RA.ApplicationOwnerUserid ,U.FName +' ' +U.LName as[ApplicationOwner]
FROM dbo.[Application] A 
JOIN dbo.[RFIApplication] RA ON RA.ApplicationID=A.ID
JOIN dbo.RFI R ON R.ID=RA.RFIID 
JOIN dbo.RFICampaign AS RC ON RC.RFIID = R.ID AND RC.CampaignID =@currentcampaignid 
JOIN dbo.[User]  U ON U.ID =RA.ApplicationOwnerUserid AND U.IsActive =1
WHERE RA.ApplicationOwnerUserid  IN ( select  cast([value] as bigint) as ID from STRING_SPLIT (@Appownerid, ',') )

UNION 

SELECT DISTINCT
R.ID,
R.RFITrackingID AS RFITracking,RA.ApplicationOwnerUserid ,U.FName +' ' +U.LName as[ApplicationOwner]
FROM dbo.RFI R
JOIN dbo.RFICampaign AS RC ON RC.RFIID = R.ID AND RC.CampaignID =@currentcampaignid 
JOIN dbo.RFIDelegate RD ON RD.RFIID =R.ID AND RD.IsActive =1
JOIN dbo.[RFIApplication] RA ON RA.RFIID =R.ID
JOIN dbo.[User]  U ON U.ID =RA.ApplicationOwnerUserid AND U.IsActive =1
WHERE [DelegateUserID]=@delegateid 
END

IF((@Appownerid='0') AND (isnull(@delegateid,0)>0))
BEGIN
SELECT DISTINCT
R.ID,
R.RFITrackingID AS RFITracking,RA.ApplicationOwnerUserid ,U.FName +' ' +U.LName as[ApplicationOwner]
FROM dbo.RFI R
JOIN dbo.RFICampaign AS RC ON RC.RFIID = R.ID AND RC.CampaignID =@currentcampaignid 
JOIN dbo.RFIDelegate RD ON RD.RFIID =R.ID AND RD.IsActive =1
JOIN dbo.[RFIApplication] RA ON RA.RFIID =R.ID
JOIN dbo.[User]  U ON U.ID =RA.ApplicationOwnerUserid AND U.IsActive =1
WHERE [DelegateUserID]=@delegateid 
END



END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  StoredProcedure [dbo].[GetRFIUserListDetails]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 9/22/2021
-- Description: GetRFIUserListDetails
-- Purpose :Get Userlist  RFI information by passing MAP RFID or AMP TrackingId
--EXEC GetRFIUserListDetails 234
 =========================================================
 */


CREATE PROC [dbo].[GetRFIUserListDetails] 
(
 @rfdid BIGINT
)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY


--select CONVERT(varchar,termeddate,101),termeddate,* from dbo.[user] where id=136524
DROP TABLE IF EXISTS #TempUList

--Get Formated UserList based on RFDID
SELECT DISTINCT
	U.ID AS [Uid],
RTRIM(LTRIM(REVERSE(FQ.[Description]) + SUBSTRING(FY.[Description],3,2)+' '+ISNULL(RGP.[Description],''))) AS  [ReviewID],
	ISNULL(B.BUName,'') AS [BU],
	ISNULL(AP.APMNumber,'') AS [UAID],
	ISNULL(A.[Description],'') AS [Asset] ,
	ISNULL(A.AssetDetails,'') AS [AssetDetails],
	ISNULL(A.AssetNote,'') AS [AssetNote],
	ISNULL(U.FName,'') AS [FirstName],
	ISNULL(U.LName,'') AS [LastName],
	ISNULL(U.UserName,'') AS [UserId],
	ISNULL(RO.[Role],RO.[Description]) AS [Role],	
	ISNULL(U.EmpID,'') As [EmployeeID],
	ISNULL(CONVERT(varchar(12),U.TermedDate,101),'') AS [Termdate],
	dbo.UdfGetuserValidationError(U.ID)  AS ErrorMessage,
	RO.ID  as[RoleId],
	A.ID AS [AssetId],
	ISNULL(CONVERT(varchar(12),U.LastLogon,101),'') AS LastLogin
	INTO #TempUList
FROM
dbo.UserRFI UR
		INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive =1
	INNER JOIN dbo.BU B ON B.ID=U.BUID AND B.IsActive =1
	LEFT JOIN [dbo].[UserAsset] UA ON UA.UserID=U.ID
	LEFT JOIN [dbo].[Asset] A ON A.ID=UA.AssetID AND A.IsActive =1
	LEFT JOIN [dbo].[UserRole] UR1 ON UR1.UserId=U.ID
	Left JOIN [dbo].[Role] RO ON RO.Id=UR1.Roleid AND RO.IsActive=1
	INNER JOIN [dbo].RFICampaign RC ON RC.RFIID =UR.RFIID 
	INNER JOIN [dbo].Campaign C ON C.ID =RC.CampaignID AND C.IsActive =1
	INNER JOIN [dbo].[RFIApplication] RFA  ON  RFA.RFIID =UR.RFIID 
	INNER JOIN [FinancialQuarter] FQ ON  FQ.ID=C.FQID
	INNER JOIN [FinancialYear] FY ON FY.ID=C.FYID
	INNER JOIN [dbo].[RFI] R ON R.Id=UR.RFIID 
	LEFT JOIN [dbo].[RFIGroup] RGP ON RGP.ID=R.RFIGroupID  
		INNER JOIN [dbo].[Application] AP ON AP.ID =RFA.ApplicationID AND AP.IsActive =1	
	WHERE UR.RFIID=@rfdid  AND U.ID NOT IN (SELECT USERID FROM dbo.UserLogin)
	ORDER BY U.ID ASC


	SELECT *,ROW_NUMBER() OVER (ORDER BY[Uid]) AS [GUID] FROM  #TempUList

	
	
END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END


--Completion time: 2022-01-06T05:33:10.3562518-06:00
GO
/****** Object:  StoredProcedure [dbo].[GetWorkdayDetails]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 12/08/2021
-- Description: Get Workday details based on fname and Lname 
-- EXEC [dbo].[GetWorkdayDetails] 'Gregory','brown'
 =========================================================
*/

CREATE   PROC [dbo].[GetWorkdayDetails] 
(
@Fname varchar(100),
@Lname varchar(100)
)
AS
BEGIN-- Executable Section BEGIN 
BEGIN TRY


SET @Fname=LTRIM(RTRIM(@Fname))
SET @Lname=LTRIM(RTRIM(@Lname))

SELECT 
W.HREmployeeID,
W.LegacyID,
W.HRFirstName,
W.HRLastName,
ISNULL(W.HRMiddleName,'') AS[HRMiddleName],
CONVERT(varchar(12),W.HRHireDate,101) as [HRHireDate],
HJF.[Description] AS [HRJobFamily],
HOT.[Description] AS [HROfficeTitle], 
HCJ.[Description] AS [HRCenterJobTitle] ,
HS.[Description] AS [HRSource], 
HRS.[Description] AS [HRStatus],
ISNULL(HRSUP.HREmployeeID,0) As[HRSupervisorID],
ISNULL(HRSUP.HRFirstName +' '+ HRSUP.HRLastName,'') as[HRSupervisorName],
CONVERT(varchar(12),ISNULL(W.HRTermDateInitiated,''),101) as [HRTermDateInitiated],
CONVERT(varchar(12),ISNULL(W.HRTermDateEffective,''),101) as [HRTermDateEffective],
W.HREeCategory,
W.EmailAddress,
ISNULL(W.Phone,'') AS[Phone],
ISNULL(W.PhoneBusinessExtension,'') AS [PhoneBusinessExtension],
ISNULL(W.PhoneMobile1,'') As[PhoneMobile1],
W.ADLogonName,
HG.[Description] AS [HRGroup],
HD.[Description] AS [HRDivision],
HBU.[Description] AS [HRBusinessUnitName],
ISNULL(HUL.[Description],'') AS [LocationName],
ISNULL(HUL.AddressLine1 ,'') As [LocationAddress1],
ISNULL(HST.[Description],'') AS [LocationStateName],
ISNULL(HST.[StateProvinceCode],'') AS [LocationStateProvince],
ISNULL(HUL.PostalCode,'') AS [LocationPostalCode],
ISNULL(HCO.[Description],'') AS [LocationCountry],
ISNULL(HCO.[CountryISOCode],'') AS [LocationISOCode]
FROM dbo.WorkDay W
JOIN dbo.HRJobFamily HJF ON HJF.ID=W.HRJobFamilyId 
JOIN dbo.HROfficeTitle HOT ON HOT.Id=W.HROfficeTitleId 
JOIN dbo.HRCenterJobTitle HCJ ON HCJ.ID=W.HRCenterJobTitleId 
JOIN dbo.HRSource  HS ON HS.Id=W.HRSourceId 
JOIN dbo.HRStatus HRS ON HRS.ID=W.HRStatusId 
JOIN dbo.HRGroup HG ON HG.ID=W.GroupNameId 
JOIN dbo.HRDivision HD ON HD.ID =W.DivisionNameId 
JOIN dbo.HRBusinessUnit HBU ON HBU.ID =W.BusinessUnitNameId 
LEFT JOIN  dbo.HRUserLocation HUL ON HUL.Id=W.HRLocationId 
LEFT JOIN dbo.HRCity HCI ON HCI.Id=HUL.HRCityId 
LEFT JOIN dbo.HRState HST ON HST.ID=HUL.HRStateId 
LEFT JOIN dbo.HRCountry HCO ON HCO.ID=HUL.HRCountryId  
LEFT JOIN dbo.WorkDay HRSUP ON HRSUP.ID=W.HRSupervisorID 
WHERE W.HRFirstName=@Fname AND W.HRLastName =@Lname 
ORDER BY W.HRFirstName,W.HRLastName ASC
END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END


GO
/****** Object:  StoredProcedure [dbo].[InsertRFIData]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 9/9/2021
-- Description: Insert Data From Staging to Multiple RFI tables 
-- Update Date: 9/21/2021
-- Update by:Binu and john 
-- Update description: updated Application table if APMnumber and UAID Changes and Apptemplate insert based on application changes
---EXEC dbo.[InsertRFIData]
 =========================================================
*/



CREATE     procedure [dbo].[InsertRFIData]
AS
BEGIN

declare @FYQid int
declare @FYid int
declare @CampaignId bigint
declare @RFId bigint
declare @rowcount int
declare @stgFQ varchar(10)
declare @whilecount int
declare @rfistatusid int
declare @rfistatus varchar(100)
declare @RFItrackid varchar(250)
declare @application varchar(500) 
declare @appuaid varchar(250)
declare @APMnumber varchar(250)
declare @duedate varchar(50)
declare @bu varchar(100)
declare @appowner varchar(500)
declare @appid bigint
declare @buid bigint
declare @Userid bigint
declare @startdt datetime
declare @EndDt datetime
declare @stgFY varchar(10)
declare @rfigroup varchar(20)
declare @rfigroupid int
declare @rfidataneeded varchar(20)
declare @rfiDataid int
declare @rfidelegate varchar(1000)
declare @rfidelegateid int
declare @buowner varchar(250)
declare @dellname varchar(100)
declare @delfname varchar(100)
declare @dellanid varchar(100)
declare @delemialid varchar(100)
declare @delegatewhilecount int
declare @delegaterowcount int
declare @dlname varchar(100)
declare @dfname varchar(100)
declare @dlanid varchar(100)
declare @demailid varchar(100)
declare @deluserid bigint
declare @amprfiStatus varchar(100)
declare @rfiBU varchar(250)
declare @rfiACG varchar(50)
declare @rejecttype varchar(250)
declare @rficomments varchar(5000)
declare @rfirejecttypeid int
declare @acgid int
declare @rfibuid int
declare @RFDroleid int
DECLARE @createdUserid bigint
Declare @approleid int
declare @AOfname varchar(100)
declare @AOLname varchar(100)
declare @AOusername varchar(250)
declare @AOemailid varchar(100)
declare @acgstatus varchar(100)
declare @acgstatusid int

SELECT @createdUserid=ID FROM dbo.[USER] WHERE  [UserName]='AMPUser'



SET @FYQid=0;
SET @FYid=0;
set @RFId=0;

BEGIN TRY
BEGIN TRANSACTION
	DELETE From dbo.StagingRFI WHERE ISNULL([RFI ID],'')=''

	SELECT @rowcount=count(*) from [dbo].[StagingRFI]  


SET @whilecount =0

 

SELECT *, number = ROW_NUMBER() OVER (ORDER BY[RFI ID])
INTO #TempStaging
  FROM dbo.StagingRFI
  ORDER BY [RFI ID]

  
 
	DELETE T 
	FROM #TempStaging T
	JOIN dbo.RFI R ON R.RFITrackingID =T.[RFI ID] 
	JOIN dbo.RFIStatusLog RSL ON RSL.RFIID=R.ID AND RSL.IsActive=1
	JOIN dbo.RFIStatus RS ON RS.ID =RSL.RFIStatusID   
   WHERE (LTRIM(RTRIM(UPPER(RS.[Description])))=UPPER('Complete/Certification started') AND LTRIM(RTRIM(UPPER(T.[Status])))=UPPER('Complete/Certification started'))
	OR LTRIM(RTRIM(UPPER(RS.[Description]))) IN (UPPER('Submitted/Pending Acceptance'),UPPER('Accepted/Processing'),UPPER('Closed/Incomplete') )


	--select *from #TempStaging
WHILE @whilecount< @rowcount
BEGIN
	SET @whilecount=@whilecount+1
	SET @delegatewhilecount=0

	IF EXISTS (select *from #TempStaging WHERE number=@whilecount)
	BEGIN

	SELECT @RFItrackid=[RFI ID],
	@rfistatus=[Status],
	@duedate=[Due Date],
	--@appuaid=[AppMap UAID],
	@APMnumber=[APM Number],
	@application=[Application Name],
	--@bu=BU,
	@appowner=LTRIM(RTRIM([IT Application owner])),
	@stgFQ=[Campaign Qtr],
	@stgFY=[Campaign FY],
	@rfigroup=[Application Category],
	@rfiDataneeded=[Data Needed],
	@buowner=[Business Owner],
	@rfidelegate=[Delegate],
	@rfiBU =BusinessGroup,
	@rfiACG =ACG ,
	@rejecttype=RejectedType,
	@rficomments=Generalcomments,
	@acgstatus=LTRIM(RTRIM(ACGStatus))
	FROM #TempStaging WHERE number=@whilecount



	SELECT @startdt = CASE WHEN LTRIM(RTRIM(@stgFQ))=1 THEN ltrim(rtrim(@stgFY)) +'-01-01 04:27:31.023'
							  WHEN LTRIM(RTRIM(@stgFQ))=2 THEN LTRIM(RTRIM(@stgFY))+'-04-01 04:27:31.023' 
							   WHEN LTRIM(RTRIM(@stgFQ))=3 THEN LTRIM(RTRIM(@stgFY))+'-07-01 04:27:31.023'
							   ELSE LTRIM(RTRIM(@stgFY)) +'-11-01 04:27:31.023'
							   END 


	SELECT @EndDt = CASE WHEN @stgFQ=1 THEN @stgFY+'-03-30 04:05:45.713'
	WHEN @stgFQ=2 THEN @stgFY+'-06-30 04:05:45.713' 
	WHEN @stgFQ=3 THEN @stgFY+'-10-21 04:05:45.713'
	ELSE @stgFY+'-12-31 04:05:45.713'
	END 

	
	
	SELECT @FYQid=ID FROM [dbo].[FinancialQuarter] WHERE ([Description]) LIKE  'Q' + @stgFQ +'%'
	
---[FinancialYear]

	IF NOT EXISTS (select *from [dbo].[FinancialYear] where [Description] LIKE  '%' + @stgFY +'%')
	BEGIN
	--UPDATE [dbo].[FinancialYear] SET IsActive =0  WHERE year(convert(datetime,[Description],103))<year(convert(datetime,@stgFY,103))
	INSERT INTO [dbo].[FinancialYear]([Description],IsActive)values (@stgFY,1)
	SET @FYid=Scope_Identity()
	END
	ELSE
	BEGIN
	SELECT @FYid=ID FROM [dbo].[FinancialYear] WHERE ([Description]) LIKE  '%' + @stgFY +'%' AND IsActive =1
	END

---campaign	
	IF(@FYid<>0 AND @FYQid<>0)
	BEGIN
		 IF NOT EXISTS (SELECT *FROM  [dbo].[Campaign] WHERE [FYID]=@FYid AND [FQID]=@FYQid)
		 BEGIN
		-- UPDATE  [dbo].[Campaign] SET IsActive =0 WHERE CAST ([FYID]  as int) < CAST(@stgFY AS INT)
			INSERT INTO [dbo].[Campaign] ([Description], [FYID], [FQID], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
			VALUES ('',@FYid,@FYQid,1,@createdUserid,getdate(),NULL,NULL)
			SET @CampaignId=Scope_Identity()
		END
		ELSE
		BEGIN
		SELECT @CampaignId=ID FROM [Campaign] WHERE FYID=@FYid AND [FQID]=@FYQid
		END
	
--campaign periodprint 
			IF NOT EXISTS (SELECT *FROM [dbo].[Campaignperiod] WHERE [CampaignID]=@CampaignId)
			BEGIN
			INSERT INTO [dbo].[Campaignperiod]([CampaignID], [StartDt], [EndDt])VALUES (@CampaignId,@startdt ,@EndDt)
			END
			
			

	END --campaign end

	------RFI Group
	--@rfigroup,@rfidataneeded
	IF NOT EXISTS(SELECT *FROM [dbo].[RFIGroup] WHERE RTRIM(LTRIM([Description])) =LTRIM(RTRIM(@rfigroup)) AND ISNULL(@rfigroupid,'')!='')
	BEGIN 
	INSERT INTO [dbo].[RFIGroup] ([Description], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
	VALUES(LTRIM(RTRIM(@rfigroup)),1,@createdUserid,getdate(),NULL,NULL)
	SET @rfigroupid=Scope_Identity()
	END
	ELSE
	BEGIN
	SELECT @rfigroupid=ID FROM [dbo].[RFIGroup] WHERE RTRIM(LTRIM([Description])) =LTRIM(RTRIM(@rfigroup))

	END

	---DataNeeded

	IF NOT EXISTS(SELECT *FROM [dbo].[RFIDataNeeded] WHERE [Description] =LTRIM(RTRIM(@rfiDataneeded)) AND ISNULL(@rfiDataneeded,'')!='')
	BEGIN 
	INSERT INTO [dbo].[RFIDataNeeded] ([Description], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
	VALUES(LTRIM(RTRIM(@rfiDataneeded)),1,@createdUserid,getDate(),NULL,NULL)
	SET @rfiDataid=Scope_Identity()
	END
	ELSE
	BEGIN
	SELECT @rfiDataid=ID FROM  [dbo].[RFIDataNeeded] WHERE [Description] =LTRIM(RTRIM(@rfiDataneeded))
	END

	--RFI BU
	---BU
	IF NOT EXISTS (SELECT *FROM dbo.BU WHERE [BUName]=LTRIM(RTRIM(@rfiBU)) AND ISNULL(@rfiBU,'')!='')
	BEGIN
	INSERT INTO dbo.BU ([BUName], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
	VALUES(@rfiBU,1,@createdUserid,getdate(),NULL,NULL)
	SET @rfibuid=Scope_Identity()
	END
	ELSE
	BEGIN
	SELECT @rfibuid=ID  FROM  dbo.BU WHERE [BUName]=@rfiBU and [IsActive]=1

	END


	-------RFI

	IF NOT EXISTS (SELECT * FROM dbo.RFI R WHERE  R.RFITrackingID =@RFItrackid)
	BEGIN	
			INSERT INTO dbo.RFI([Description],RFITrackingID,IsActive,CreatedBy,CreatedDt,ModifiedBy,ModifiedDt,
			BusinessOwner,RFIGroupID,DataNeeded,BUID) 
			VALUES('',@RFItrackid,1,@createdUserid,getdate(),NULL,NULL,@buowner,@rfigroupid,@rfiDataid,@rfibuid)
			SET @RFId=Scope_Identity()

	END
	ELSE
	BEGIN
	SELECT @RFId=ID FROM dbo.RFI R WHERE  R.RFITrackingID =@RFItrackid 

	UPDATE  dbo.RFI SET 
	BusinessOwner=@buowner,
	RFIGroupID=@rfigroupid,
	DataNeeded=@rfiDataid,
	BUID=@rfibuid,
	ModifiedBy=@createdUserid,
	ModifiedDt=GETDATE()
	WHERE ID=@RFId AND (BusinessOwner!=@buOwner OR RFIGroupId!=@rfigroupid  OR DataNeeded!=@rfidataid OR BUID!=@rfibuid)

	END

	--ACG
	IF(ISNULL(@rfiACG,'')!='')
	BEGIN



		IF NOT EXISTS(SELECT  *FROM [dbo].[ACGStatus] WHERE [Description]=@acgstatus)
		BEGIN

			INSERT INTO [dbo].[ACGStatus]([Description],IsActive,CreatedBy,CreatedDt,ModifiedBy,ModifiedDt)
					VALUES(@acgstatus,1,@createdUserid,getdate(),NULL,NULL)
					SET @acgstatusid=Scope_Identity()
		END
		ELSE
		BEGIN
				SELECT @acgstatusid=ID FROM [dbo].[ACGStatus] WHERE[Description]=@acgstatus
		END



		IF NOT EXISTS(SELECT *FROM dbo.ACG WHERE [Description]=@rfiACG)
		BEGIN


		INSERT INTO dbo.ACG([Description],IsActive,CreatedBy,CreatedDt,ModifiedBy,ModifiedDt)
		VALUES (@rfiACG,1,@createdUserid,getdate(),NULL,NULL)
		SET @acgid=Scope_Identity()
		END
		ELSE
		BEGIN
	
		SELECT @acgid=ID FROM  dbo.ACG WHERE [Description]=@rfiACG
		END


	--RFI/RFD ACG
	IF NOT EXISTS(SELECT *FROM dbo.RFDACG WHERE RFDID=@RFId AND ACGID= @acgid)
	BEGIN
	
	INSERT INTO dbo.RFDACG([RFDID], [ACGID], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt],ACGStatus) 
	VALUES(@RFId  ,@acgid,@createdUserid,GETDATE(),NULL,NULL,@acgstatusid)
	END
	ELSE
	BEGIN
	UPDATE dbo.RFDACG SET [ACGID]=@acgid,[ACGStatus]=@acgstatusid,[ModifiedBy]=@createdUserid, [ModifiedDt]=GETDATE() WHERE RFDID=@RFId
	END
	END

	

	---RFI Campaign

	IF NOT EXISTS (SELECT *FROM dbo.RFICampaign WHERE RFIID=@RFId)
	BEGIN
		INSERT INTO dbo.RFICampaign ([RFIID], [CampaignID], [AssignDt]) VALUES (@RFId,@CampaignId,getdate())
	END
	ELSE
	BEGIN

	UPDATE dbo.RFICampaign  SET @CampaignId=@CampaignId WHERE [RFIID]=@RFId

	END

-- RFI Status
print @rfistatus
	SELECT @rfistatusid=ID FROM [dbo].[RFIStatus] WHERE [Description]=@rfistatus  aND IsActive =1
	print @rfistatusid
	IF(@rfistatusid IS NULL)
	BEGIN
		SELECT @rfistatusid=ID FROM [dbo].[RFIStatus] WHERE [Description]='Returned' aND IsActive =1
		set @rficomments= COnvert(varchar(10),getdate(),101) +' - '+@rfistatus +' Status is not supported by AMP'
		set @rejecttype='Incorrect Data Sent'
	END

	IF (ISNULL(@rejecttype,'')!='')
	BEGIN
			IF NOT EXISTS(SELECT *FROM dbo.RejectType WHERE [Description]=@rejecttype)
			BEGIN
				INSERT INTO dbo.RejectType([Description], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
				VALUES(@rejecttype,1,@createdUserid,getdate(),NULL,NULL)
				SET @rfirejecttypeid=Scope_Identity()
			END
			ELSE
			BEGIN
				SELECT @rfirejecttypeid= ID  FROM  dbo.RejectType WHERE [Description]=@rejecttype
			END
	END

	print @RFId
	print @RFItrackid
	print @rfistatusid
	IF NOT EXISTS (SELECT * FROM RFIStatusLog WHERE [RFIID]=@RFId)
	BEGIN
		IF NOT EXISTS (SELECT * FROM RFIStatusLog WHERE [RFIID]=@RFId and  [RFIStatusID]=@rfistatusid)
		BEGIN
		INSERT INTO dbo.RFIStatusLog([RFIID], [RFIStatusID], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt],RejectTypeid,Comments)
		VALUES( @RFId,@rfistatusid,1,@createdUserid,getdate(),NULL,NULL,@rfirejecttypeid,@rficomments)
		END
	END
	ELSE
	BEGIN
		UPDATE RFIStatusLog SET IsActive=0,[ModifiedBy]=@createdUserid, [ModifiedDt]=GetDate() WHERE [RFIID]=@RFId 
		IF NOT EXISTS (SELECT * FROM RFIStatusLog WHERE [RFIID]=@RFId and  [RFIStatusID]=@rfistatusid )
		BEGIN
		INSERT INTO dbo.RFIStatusLog([RFIID], [RFIStatusID], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt],RejectTypeid,Comments)
		VALUES( @RFId,@rfistatusid,1,@createdUserid,getdate(),NULL,NULL,@rfirejecttypeid,@rficomments)
		END
		ELSE
		BEGIN
				UPDATE RFIStatusLog SET IsActive=1,[ModifiedBy]=@createdUserid, [ModifiedDt]=GetDate(),RejectTypeid=@rfirejecttypeid,Comments=@rficomments WHERE [RFIID]=@RFId and [RFIStatusID]= @rfistatusid
		END
		

	END

----RFIduedate

	IF NOT EXISTS (SELECT *FROM [dbo].[RFIDueDt] WHERE [RFIID]=@RFId )
	BEGIN
		 
		 INSERT INTO [dbo].[RFIDueDt] ([RFIID], [DueDate], [IsActive]) VALUES(@RFId,CONVERT(datetime,@duedate,101),1)---CONVERT(datetime,CAST(CONVERT(date,@duedate,105) as datetime ),101)
	END
	ELSE
	BEGIN

	DECLARE @RDT INT 
	SELECT @RDT=ID FROM [dbo].[RFIDueDt] wHERE [RFIID]=@RFId

	UPDATE [dbo].[RFIDueDt] SET [DueDate] =CONVERT(datetime,@duedate,101) WHERE [RFIID]=@RFId 

END


	
----------application 
		IF NOT EXISTS (SELECT *FROM [dbo].[Application]  WHERE [Description]=@application AND [IsActive]=1 AND [APMNumber]=@APMnumber)
		BEGIN
		
			IF EXISTS (SELECT * FROM [dbo].[Application] WHERE [APMNumber]=@APMnumber AND  [IsActive]=1) --APMnumber updated but appname is same
			BEGIN
				UPDATE [dbo].[Application] SET [IsActive]=0,ModifiedBy=@createdUserid,ModifiedDt=getdate()
				WHERE [APMNumber]=@APMnumber AND  [IsActive]=1
			END
			INSERT INTO [dbo].[Application] ([Description], [UAID], [APMNumber], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
			VALUES(@application,NULL,@APMnumber,1,@createdUserid,getdate(),NULL,NULL)
			SET @appid=Scope_Identity()
			
			
		END
		ELSE
		BEGIN
		
		SELECT @appid=ID FROM  [dbo].[Application]  WHERE [Description]=@application AND [IsActive]=1  AND [APMNumber]=@APMnumber
		IF EXISTS (SELECT * FROM [dbo].[Application] WHERE ID=@appid AND (COALESCE([APMNumber],'') <> COALESCE(@APMnumber,'')))
			BEGIN   
						UPDATE [dbo].[Application] SET [IsActive]=0,ModifiedBy=@createdUserid,ModifiedDt=getdate() WHERE ID=@appid

						INSERT INTO [dbo].[Application] ([Description], [UAID], [APMNumber], [IsActive], [CreatedBy],[CreatedDt], [ModifiedBy], [ModifiedDt])
						VALUES(@application,NULL,@APMnumber,1,@createdUserid,getdate(),NULL,NULL)

						SET @appid=Scope_Identity()

				  		IF EXISTS (SELECT * FROM [dbo].[AppTemplate] WHERE [ApplicationID]=@appid AND ISDEFAULT=1)
					    BEGIN 
												
						UPDATE  [dbo].[AppTemplate] SET [ApplicationID]=@appid,ModifiedBy=@createdUserid,ModifiedDt=getdate()
						WHERE [ApplicationID]=@appid AND ISDEFAULT=1
								
					--END
				END
			END
		END
		
		DROP TABLE IF EXISTS #TempAppowner

IF(@appowner<>'AMPUser')--match with lanid
BEGIN


				SELECT * INTO  #TempAppowner  FROM  dbo.[UdfAORFDSplitString] (@appowner)
				--SELECT @AOfname=T.FirstName ,@AOLname=T.LastName,@AOusername=ISNULL(T.Lanid,ISNULL(T.Email,'')),@AOemailid=ISNULL(T.Email,'') from #TempAppowner T
				SELECT @AOfname=LTRIM(RTRIM(T.FirstName)) ,@AOLname=LTRIM(RTRIM(T.LastName)),@AOusername=LTRIM(RTRIM(ISNULL(T.Lanid,ISNULL(T.Email,'')))),@AOemailid=LTRIM(RTRIM(ISNULL(T.Email,''))) from #TempAppowner T


				IF(CHARINDEX('@', @AOemailid)>0)
				BEGIN
					SELECT @AOusername=ADLogonName FROM DBO.WorkDay WHERE EmailAddress=@AOemailid AND HRFirstName =@AOfname and HRLastName =@AOLname
				END

		IF NOT EXISTS (SELECT * FROM [dbo].[User] WHERE UPPER([UserName])=UPPER(@AOusername) AND UPPER([LName])= UPPER(@AOLname) AND UPPER([Fname])= UPPER(@AOfname) AND @AOusername!='') --username,fname,lname check condition,username -substring from appowner
					
		BEGIN
		
				INSERT INTO [dbo].[User]([UserName], [EmpID], [ReportsTo], [BUID], [LName], [FName], [Phone], [Zip],
				[Email], [TermedDate], [HRStatusID], [HRCurrStatusID], [HRBU], [CompanyID], [BSPChannelID], [BTChannelID], 
				[ValidationID], [ChangeID], [SecAnswerID], [BankFIID], [CmsChain], [SalesID], [RegionID], [AddComments],
				[IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt],Stale)
				VALUES (
				@AOusername, null, null, @rfibuid,
				@AOLname,  
				@AOfname,
				NULL,NULL,@AOemailid, null, null, null, null, null, null, null,null, null, null, null, null, null, null, null,
				1,@createdUserid,getdate(),NULL,NULL,'')

				SET @Userid=Scope_Identity()
		DROP TABLE #TempAppowner
		END
		ELSE 
		BEGIN
		SELECT @Userid=ID FROM [dbo].[User] WHERE [UserName]=@AOusername AND [LName]= @AOLname AND [Fname]= @AOfname

		END 
		
--userlogin

		IF NOT EXISTS(SELECT *FROM [dbo].[UserLogin] WHERE UserId=@Userid)
				BEGIN	
			INSERT INTO dbo.UserLogin(UserID,LoginAttmpt,LogInDt,LogOutDt,IsLocked)
						VALUES(@Userid,1,GETDATE(),GETDATE(),0)
						
		END
--Role

SELECT @approleid=ID FROM dbo.[Role] WHERE Role='ApplicationOwner'

--USERROLE

		IF NOT EXISTS(SELECT *FROM [dbo].[UserRole] WHERE UserId=@Userid and RoleId=@approleid)
		BEGIN
		INSERT INTO [dbo].[UserRole]([UserID], [RoleID])
		VALUES (@Userid,@approleid)			
		END
	
--UserRFI 
	--IF NOT EXISTS(SELECT *FROM [dbo].[UserRFI] WHERE ([UserID]=@Userid AND [RFIID]=@RFId ))
	--	BEGIN
	--	INSERT INTO [dbo].[UserRFI]([UserID], [RFIID], [AttestStatusID], [AssignDt], [Reportto], [UserListAppRoleId]) 
	--	VALUES(@Userid,@RFId,NULL,getdate(),NULL,NULL)
	--	END

--rfiapplication

		IF NOT EXISTS (SELECT *FROM [dbo].[RFIApplication] WHERE [RFIID]=@RFId AND  [ApplicationID]=@appid  )--AND  [ApplicationOwnerUserid]=@Userid
		BEGIN
	
			INSERT INTO [dbo].[RFIApplication]([RFIID], [ApplicationID], [AssignDt], [AssignedBy], [ApplicationOwnerUserid])
			VALUES(@RFId,@appid,getdate(),NULL,@Userid)

		END
END

		----RFIDelegate
	IF ((ISNULL(@rfidelegate,'') !='') AND (CHARINDEX(',',@rfidelegate)>0))
	BEGIN
	
		SELECT *, Number = ROW_NUMBER() OVER (ORDER BY LastName)
		INTO #TempDelegate  FROM dbo.[UdfAORFDSplitString](@rfidelegate)  ORDER BY LastName

		  SELECT @delegaterowcount=count(*) FROM #TempDelegate

		WHILE @delegatewhilecount<@delegaterowcount 
		BEGIN 

				SET @delegatewhilecount=@delegatewhilecount+1

				SELECT 
				@dlname=LTRIM(RTRIM(LastName)),
				@dfname=LTRIM(RTRIM(FirstName)),
				@dlanid=LTRIM(RTRIM(Lanid)),
				@demailid=LTRIM(RTRIM(Email))
				FROM  #TempDelegate WHERE NUMBER=@delegatewhilecount

				IF(CHARINDEX('@', @demailid)>0)
				BEGIN
					SELECT @dlanid=ADLogonName FROM DBO.WorkDay WHERE EmailAddress=@demailid AND HRFirstName =@dfname and HRLastName =@dlname
				END
				--USER

		---add delegate user
		IF(ISNULL(@dlanid,'')!='') AND (@dlanid<>'AMPUser')
		BEGIN
		
	

				--IF NOT EXISTS (SELECT * FROM [dbo].[User] US
				--WHERE (US.Lname =@dlname AND US.Fname=@dfname AND US.UserName=@dlanid))										
				--BEGIN
				IF NOT EXISTS (SELECT * FROM [dbo].[User] WHERE UPPER([UserName])=UPPER(@dlanid) AND UPPER([LName])= UPPER(@dlname) AND UPPER([Fname])= UPPER(@dfname) AND @dlanid!='') 
				BEGIN
				INSERT INTO [dbo].[User]([UserName], [EmpID], [ReportsTo], [BUID], [LName], [FName], [Phone], [Zip],
						[Email], [TermedDate], [HRStatusID], [HRCurrStatusID], [HRBU], [CompanyID], [BSPChannelID], [BTChannelID], 
						[ValidationID], [ChangeID], [SecAnswerID], [BankFIID], [CmsChain], [SalesID], [RegionID], [AddComments],
						[IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt],Stale)				 
						SELECT @dlanid,null, null, @rfibuid,
						@dlname,  --TRIM(SUBSTRING(@appowner, CHARINDEX(' ', @appowner),len(@appowner))),
						@dfname, --TRIM(SUBSTRING(@appowner, 0, CHARINDEX(' ', @appowner))), '', 
						NULL,NULL, @demailid , null, null, null, null, null, null, null,null, null, null, null, null, null, null, null,
						1,@createdUserid,getdate(),NULL,NULL,''
						
				SET @deluserid=Scope_Identity()

				--UserLogin 
				INSERT INTO dbo.UserLogin(UserID,LoginAttmpt,LogInDt,LogOutDt,IsLocked)
				VALUES(@deluserid,1,GETDATE(),GETDATE(),0)
				
				SELECT @RFDroleid=ID FROM dbo.[Role] where [Role]='RFDDelegate'

				INSERT INTO dbo.UserRole(UserID,RoleID) VALUES (@deluserid,@RFDroleid)

				END
				ELSE
				BEGIN
				SELECT @deluserid=ID FROM [dbo].[User] US
				WHERE (US.Lname =@dlname AND US.Fname=@dfname AND US.UserName=@dlanid)
				END 
		END
		ELSE
		BEGIN
		SET @deluserid=0
		END
	

		----RFIDelegate @rfidelegate

				IF NOT EXISTS (SELECT *FROM [dbo].[RFIDelegate] WHERE [RFIID]=@RFId  AND Lname =@dlname 
						AND Fname=@dfname)
				BEGIN
			
					INSERT INTO [dbo].[RFIDelegate]([RFIID], [Lname], [Fname], [LanId], [EmailId], [DelegateUserID], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
								VALUES(@RFId,@dlname,@dfname,@dlanid,@demailid,@deluserid,1,@createdUserid,getdate(),NULL,NULL)
							
				END
		END--delegate While

			DROP TABLE #TempDelegate
	END--check delegate exits or not
 END--record not exists
END --While end

DROP TABLE #TempStaging


COMMIT TRANSACTION
END TRY	-- Executable Section END

-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
SELECT 
@ErrorMessage = ERROR_MESSAGE(), 
@ErrorSeverity = ERROR_SEVERITY(), 
@ErrorState = ERROR_STATE(); 
 
-- Use RAISERROR inside the CATCH block to return error 
-- information about the original error that caused 
-- execution to jump to the CATCH block. 
RAISERROR (
@ErrorMessage, -- Message text. 
 @ErrorSeverity, -- Severity. 
 @ErrorState -- State. 
); 
END CATCH;
-- Exception Handling Section END

END

GO
/****** Object:  StoredProcedure [dbo].[SaveExtractDataFromRawFile ]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
/* ========================================================  
Author: TUSHAR CHAKRABORTY  
Create Date: 24/09/2021  
Description: Get RFI and File detals  
Modified By:  Krrishnajayanthi
Modified Date:  01/11/2022
Reason:  
Dependencies:  
[RFI],[RFIStatusLog],[RFIStatus],[UserRFI],[User],[UserRole],[Role],[AppUser],[Application],  
[RFIDocument],[Document],[DocumentType],[Template],[TemplateType],[FTAmpdocuments]  
Output list: BOOLEAN (TRUE / FALSE)  
Executable Command: EXEC SaveExtractDataFromRawFile  
@RFIID = 0,   
@UserID = 1,   
@ApplicaitonID = 0,   
@TemplateID = 0,   
@DocumentID = 'dcf88db1-3f1d-ec11-  
86c5-40e2303b788b',  
@JSONData = '[   
 {   
"UserData": {   
   
"UserName":"TUSHAR",  
   
"LastName":"CHAKRABORTY",   
   
"FirstName":"TUSHAR",  
   
"Role":"ABC",  
   
"BU":"ABC",  
   
"Asset":"ABC",  
   
"AssetDetails":"ABC",  
   
"AssetNotes":"ABC",  
   
"Status":"ABC",  
   
"EmployeeId":"5043659",  
   
"TermedDate":"2011-06-01T00:00:00",  
   
"Stale":"ABC",  
   
"Email":"ABC@ABC.ABC"  
}  
 },   
 {   
"UserData": {   
   
"UserName":"TUSHAR",  
   
"LastName":"CHAKRABORTY",   
   
"FirstName":"TUSHAR",  
   
"Role":"ABC",  
   
"BU":"ABC",  
   
"Asset":"ABC",  
   
"AssetDetails":"ABC",  
   
"AssetNotes":"ABC",  
   
"Status":"ABC",  
   
"EmployeeId":"5043659",  
   
"TermedDate":"2011-06-01T00:00:00",  
   
"Stale":"ABC",  
   
"Email":"ABC@ABC.ABC"  
}  
 }   
]';  
=========================================================  
*/  
CREATE    PROCEDURE [dbo].[SaveExtractDataFromRawFile ]  
(  
@RFIID BIGINT = 0,  
@UserID BIGINT = 0,  
@ApplicaitonID INT = 0,  
@TemplateID INT = 0,  
@DocumentID UNIQUEIDENTIFIER = NULL,  
@JSONData VARCHAR(MAX) = NULL  
)  
AS  
BEGIN  
SET NOCOUNT ON;  
--Declaration Section BEGIN   
DECLARE @lRFIID BIGINT = @RFIID,  
@lUserID BIGINT = @UserID,  
@lApplicaitonID INT = @ApplicaitonID,  
@lTemplateID INT = @TemplateID,  
@lDocumentID UNIQUEIDENTIFIER = @DocumentID,  
@Element_ID INT, /* internal surrogate primary key gives the order of   parsing and the list order */  
@SequenceNo INT , /* the sequence number in a list */  
@Parent_ID INT, /* if the element has a parent then it is in this   column. The document is the ultimate parent, so you can get the structure from recursing from the   document */  
@Object_ID INT, /* each list or object has an object id. This ties   all elements to a parent. Lists are treated as objects here */  
@Name NVARCHAR(2000), /* the name of the object */  
@StringValue NVARCHAR(MAX), /*the string representation of the value of the   element. */  
@ValueType VARCHAR(10),/* the declared type of the value represented   as a string in StringValue*/  
@FirstRow NVARCHAR(MAX),  
@SQL NVARCHAR(MAX),  
@ii INT = 1,  
@rowcount INT = -1,  
@null INT = 0,  
@string INT = 1,  
@int INT = 2,  
@boolean INT = 3,  
@array INT = 4,  
@object INT = 5;  


DECLARE @TheHierarchy TABLE  
 (  
 element_id INT IDENTITY(1, 1) PRIMARY KEY,  
 sequenceNo INT NULL,  
 Depth INT, /* effectively, the recursion level. the depth of   nesting*/  
 parent_ID INT,  
 ObjectID INT,  
 PColumnName NVARCHAR(2000),  
 ColumnName NVARCHAR(2000),  
 StringValue NVARCHAR(MAX),  
 ValueType VARCHAR(30)  
 );  


DROP TABLE IF EXISTS #tmpUserDetailsByRFI;  
CREATE TABLE #tmpUserDetailsByRFI  
(  
[ID] [bigint] IDENTITY(1,1) PRIMARY KEY NOT NULL,  
UserID INT,  
UserName varchar(100),  
FName varchar(100),  
LName varchar(100),  
RoleID INT,  
RoleName varchar(100),  
BUID INT,  
BUName varchar(100),  
AssetID INT,  
AssetName varchar(100),  
AssetDetails varchar(500),  
AssetNote varchar(1000),  
TermedDate datetime,  
Stale varchar(50),  
Email varchar(100),  
StatusID INT,  
LastLogon varchar(100),  
EmployeeID varchar(15)  ,
RFDDocid bigint
);  

--Declaration Section END   dbo.USERRFI,dbo.UserAsset  
-- Executable Section BEGIN   
BEGIN TRY  

SELECT TOP 1 @FirstRow = Value FROM OPENJSON(@JSONData);  

INSERT INTO @TheHierarchy  
 (sequenceNo, Depth, parent_ID, ObjectID, PColumnName, ColumnName,  
StringValue, ValueType)  
 SELECT 1, @ii, NULL, 0, '$', 'root', @FirstRow, 'object';  

WHILE @rowcount <> 0  
 BEGIN  
SET @ii = @ii + 1;  

INSERT INTO @TheHierarchy  
 (sequenceNo, Depth, parent_ID, ObjectID, PColumnName, ColumnName,  
StringValue, ValueType)  
 SELECT Scope_Identity(), @ii, ObjectID,  
Scope_Identity() + Row_Number() OVER (ORDER BY parent_ID),  
m.PColumnName + '.' + o.[Key], [Key], Coalesce(o.Value,'null'),  
CASE o.Type WHEN @string THEN 'nvarchar(1000)'  
 WHEN @null THEN 'nvarchar(1000)'  
 WHEN @int THEN 'float'  
 WHEN @boolean THEN 'boolean'  
 WHEN @array THEN 'array'  
 ELSE 'object' END  
 FROM @TheHierarchy AS m  
CROSS APPLY OpenJson(StringValue) AS o  
 WHERE m.ValueType IN ('array', 'object') AND Depth = @ii - 1;  
SELECT @rowcount = @@RowCount;  
 END;  
SET @SQL='('+(  
SELECT CHAR(13)+CHAR(10)+CHAR(9) + c.ColumnName +' ' + c.ValueType + '   
''' + c.PColumnName + ''' '  
+ CASE WHEN RANK() OVER (ORDER BY c.element_id) < COUNT(*) OVER   
() THEN ',' ELSE '' END  
FROM @TheHierarchy c  
WHERE ValueType NOT IN ('object', 'array')  
ORDER BY c.element_id  
FOR XML PATH(''), TYPE  
).value('.','nvarchar(max)')  
+CHAR(13)+CHAR(10)+')'  


SET @SQL='  
INSERT INTO #tmpUserDetailsByRFI   
(  
UserName,  
LName,  
FName,  
RoleName,  
BUName,  
AssetName,  
AssetDetails,  
AssetNote,  
LastLogon,  
EmployeeId,  
TermedDate,  
Stale,  
Email  
)  
SELECT   
UserName,  
LastName,  
FirstName,  
Role,  
BU,  
Asset,  
AssetDetails,  
AssetNotes,  
LastLogin,  
EmployeeId,  
TermedDate,  
Stale,  
Email  

FROM OPENJSON(@JSONData) WITH   
' + @SQL  

EXEC sp_executesql @SQL, N'@JSONData NVARCHAR(MAX)', @JSONData;  


--select * from #tmpUserDetailsByRFI 

BEGIN TRANSACTION;  

declare @Rfidocid bigint
declare @rfistatusid int
declare @rfirejecttypeid int 
declare @createdUserid bigint
declare @rficomments varchar(5000)

SELECT @Rfidocid=ID FROM  dbo.RFIDocument WHERE RFIID =@RFIID AND DocumentID=@DocumentID

			IF EXISTS (SELECT * FROM #tmpUserDetailsByRFI WHERE ISNULL(UserName,'')='')
			BEGIN
		--	print'came'
							SELECT @rfistatusid=Id FROM dbo.[RFIStatus]WHERE [Description] ='Returned' AND IsActive =1
							 SELECT @rficomments = CAST(FORMAT (getdate(), 'dd/MM/yyyy') as varchar(10)) + ' - UserID missing for some users'
							 SELECT @createdUserid=ID FROM dbo.[USER] WHERE  [UserName]='AMPUser'

							IF  EXISTS(SELECT *FROM dbo.RejectType WHERE [Description]='Not Enough Data Sent')
							BEGIN
								SELECT @rfirejecttypeid= ID  FROM  dbo.RejectType WHERE [Description]='Not Enough Data Sent'
							END
							ELSE
							BEGIN								
								INSERT INTO dbo.RejectType([Description], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
								VALUES('Not Enough Data Sent',1,@createdUserid,getdate(),NULL,NULL)

								SET @rfirejecttypeid=Scope_Identity()
							END												
							
							IF NOT EXISTS (SELECT * FROM RFIStatusLog WHERE [RFIID]=@RFIID and  [RFIStatusID]=@rfistatusid aND IsActive =1)
							BEGIN						
									UPDATE RFIStatusLog SET IsActive=0,[ModifiedBy]=@createdUserid, [ModifiedDt]=GetDate() WHERE [RFIID]=@RFIID 
									INSERT INTO dbo.RFIStatusLog([RFIID], [RFIStatusID], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt],RejectTypeid,Comments)
									VALUES( @RFIID,@rfistatusid,1,@createdUserid,getdate(),NULL,NULL,@rfirejecttypeid,@rficomments)

							END
							DELETE FROM #tmpUserDetailsByRFI WHERE ISNULL(UserName,'')=''
				END	
				ELSE
				BEGIN
				--return to open
				declare @rfiRTstatusid int 
				SELECT @rfistatusid=Id FROM dbo.[RFIStatus]WHERE [Description] ='Open' AND IsActive =1
				SELECT @rfiRTstatusid=Id FROM dbo.[RFIStatus]WHERE [Description] ='Returned' AND IsActive =1
				IF EXISTS (SELECT * FROM RFIStatusLog WHERE [RFIID]=@RFIID and  [RFIStatusID]=@rfiRTstatusid AND IsActive=1)
				BEGIN	
				UPDATE RFIStatusLog SET IsActive=0,[ModifiedBy]=@createdUserid, [ModifiedDt]=GetDate() WHERE [RFIID]=@RFIID 
				UPDATE RFIStatusLog SET IsActive=1,[ModifiedBy]=@createdUserid, [ModifiedDt]=GetDate() WHERE [RFIID]=@RFIID and  [RFIStatusID]=@rfistatusid
				END
						
				END
---BU insert start
		DROP TABLE IF EXISTS #tmpBUName;  
		SELECT  
		BUName  
		INTO #tmpBUName  
		FROM #tmpUserDetailsByRFI  
		WHERE ISNULL(BUName,'') !=''-- IS NOT NULL  
		GROUP BY BUName;  

		

		MERGE [BU] AS TARGET  
		USING #tmpBUName AS SOURCE  
		ON (TARGET.BUName = SOURCE.BUName)  --When records are matched, update the records if there is any change  B1=B1
		WHEN MATCHED AND TARGET.BUName <> SOURCE.BUName   
		THEN UPDATE SET TARGET.BUName = SOURCE.BUName,TARGET.IsActive=1   --When no records are matched, insert the incoming records from source table to target table  
		WHEN NOT MATCHED BY TARGET  
		THEN INSERT (BUName, [CreatedBy], [CreatedDt])  
		VALUES (SOURCE.BUName, @lUserID, GETDATE());  
		
	
		UPDATE #tmpUserDetailsByRFI  
		SET #tmpUserDetailsByRFI.BUID = B.ID  
		FROM BU B  
		WHERE #tmpUserDetailsByRFI.BUName = B.BUName;  
		DROP TABLE IF EXISTS #tmpBUName;  

		--select *from #tmpUserDetailsByRFI
		--BU END 
		---User Start
		DROP TABLE IF EXISTS #tmpUser;  
				SELECT  
				UserName,  
				FName,  
				LName,  
				left(EmployeeID, patindex('%[^0-9]%', EmployeeID+'.') - 1)as [EmployeeID],  
				BUID,  
				Email, 				
				CASE WHEN (ISDATE(TermedDate) =0 OR TermedDate='1900-01-01 00:00:00.000') THEN NULL ELSE  Convert(datetime,cast(Convert(varchar,TermedDate,102) as date),101)  END as [TermedDate],  
				Stale  ,				
				CASE WHEN (ISDATE(LastLogon) =0 OR LastLogon='1900-01-01 00:00:00.000') THEN NULL ELSE Convert(datetime,cast(Convert(varchar,LastLogon,102) as date),101)END as [LastLogon]  
				INTO #tmpUser  
				FROM #tmpUserDetailsByRFI  
				WHERE ISNULL(UserName,'')!=''
				AND  ( FName IS NOT NULL  OR  LName IS NOT NULL )  
				AND BUID IS NOT NULL  
				GROUP BY  
				UserName,FName,LName,EmployeeID,BUID,Email,TermedDate,Stale,LastLogon ;  

		--	select * from #tmpUser
				
			/*	MERGE [User] AS TARGET  
				USING #tmpUser AS SOURCE  
				ON (TARGET.UserName = SOURCE.UserName AND EXISTS (SELECT 1 FROM dbo.UserRFI WHERE RFIID=@RFIID and Userid=Target.ID) )
				--When records are matched, update the records if there is any change  
				WHEN MATCHED    
				THEN UPDATE SET TARGET.UserName = SOURCE.UserName,TARGET.FName=SOURCE.FName, LName=SOURCE.LName,Target.EmpID=SOURCE.EmployeeID,Target.Email=SOURCE.Email,
							TARGET.BUID= SOURCE.BUID, TARGET.TermedDate=SOURCE.TermedDate,TARGET.Stale=SOURCE.Stale,TARGET.ModifiedBy=@lUserID
							,ModifiedDt=GETDATE(),TARGET.IsActive=1
				--When no records are matched, insert the incoming records from source table to target table  
				WHEN NOT MATCHED BY TARGET  
				THEN INSERT (UserName, FName, LName, EmpID, BUID, Email, TermedDate,Stale, [CreatedBy], [CreatedDt])  
				VALUES (SOURCE.UserName, SOURCE.FName, SOURCE.LName, SOURCE.EmployeeID, SOURCE.BUID, SOURCE.Email, SOURCE.TermedDate, SOURCE.Stale, @lUserID,  
				GETDATE());  
		*/
		
				Declare  @updateuser TABLE (ID bigint,UserName varchar(250)) 
		
				UPDATE T SET UserName = S.UserName,FName=S.FName, LName=S.LName,EmpID=S.EmployeeID,Email=S.Email,
							BUID= S.BUID, TermedDate=S.TermedDate ,Stale=S.Stale,
							LastLogon=S.LastLogon,
							ModifiedBy=@lUserID,ModifiedDt=GETDATE(),IsActive=1
				OUTPUT UR.UserID,inserted.UserName  INTO @updateuser
				FROM dbo.[User] T,#tmpUser S,dbo.UserRFI UR
				WHERE T.UserName =S.UserName  AND UR.RFIID =@RFIID AND UR.UserID =T.ID 

			

				UPDATE #tmpUserDetailsByRFI  
				SET #tmpUserDetailsByRFI.UserID = U.ID ,RFDDocid=@Rfidocid 
				FROM @updateuser U  
				WHERE #tmpUserDetailsByRFI.UserName = U.UserName  


				Declare  @insertuser TABLE (ID bigint,UserName varchar(250)) 
				
				INSERT dbo.[User] (UserName, FName, LName, EmpID, BUID, Email, TermedDate,Stale,LastLogon, [CreatedBy], [CreatedDt])
				OUTPUT inserted.ID,inserted.UserName INTO   @insertuser			
				SELECT UserName, FName, LName, EmployeeID, BUID, Email, TermedDate, Stale,LastLogon   ,@lUserID, GETDATE()
				FROM #tmpUser S 
				WHERE NOT EXISTS  (SELECT 1 FROM dbo.[User] T WHERE T.UserName =S.UserName  AND EXISTS (SELECT 1 FROM dbo.UserRFI WHERE RFIID=@RFIID and Userid=T.ID))
				


				UPDATE #tmpUserDetailsByRFI  
				SET #tmpUserDetailsByRFI.UserID = U.ID ,RFDDocid=@Rfidocid 
				FROM @insertuser U  
				WHERE #tmpUserDetailsByRFI.UserName = U.UserName --AND U.ID> (SELECT MAX(Userid) from dbo.UserRFI  wHERE RFIID =@RFIID) 
				
				DROP TABLE IF EXISTS #tmpUser;  

				
-----User Ends
--User RFI  
			DROP TABLE IF EXISTS #tempUserRFI;  
  
			SELECT  DISTINCT
			UserId,  
			@RFIID AS RFIID  
			INTO #tempUserRFI  
			FROM #tmpUserDetailsByRFI WHERE ISNULL(UserId,0)!=0; 

			MERGE [UserRFI] AS TARGET  
			USING #tempUserRFI AS SOURCE  
			ON (TARGET.UserID = SOURCE.UserID AND TARGET.RFIID = SOURCE.RFIID)  
			WHEN NOT MATCHED BY TARGET  
			THEN INSERT (UserID, RFIID,AssignDt)  
			VALUES (SOURCE.UserID, SOURCE.RFIID,GETDATE());  

  -----user RFI end
 
  -----Role start



			DROP TABLE IF EXISTS #tmpRoleName;  

			SELECT  
			RoleName  
			INTO #tmpRoleName  
			FROM #tmpUserDetailsByRFI  
			WHERE ISNULL(RoleName,'')!=''-- IS NOT NULL  
			GROUP BY RoleName;  


			
		

			MERGE [Role] AS TARGET  
			USING #tmpRoleName AS SOURCE  
			ON (TARGET.Description = SOURCE.RoleName)  
			--When records are matched, update the records if there is any change  
			WHEN MATCHED  AND TARGET.Description <> SOURCE.RoleName  
			THEN UPDATE SET TARGET.Description = SOURCE.RoleName ,  TARGET.IsActive=1
			--When no records are matched, insert the incoming records from source table to target table  
			WHEN NOT MATCHED BY TARGET  
			THEN INSERT (Description, [CreatedBy], [CreatedDt])  
			VALUES (SOURCE.RoleName, @lUserID, GETDATE());  

		
		

			UPDATE #tmpUserDetailsByRFI  
			SET #tmpUserDetailsByRFI.RoleID = B.ID  
			FROM [Role] B  
			WHERE #tmpUserDetailsByRFI.RoleName = B.Description  
			AND #tmpUserDetailsByRFI.RoleID IS NULL;  

		 

			DROP TABLE IF EXISTS #tmpRoleName;  
--------Role end
--UserRole Start
			DROP TABLE IF EXISTS #tmpUserRole;  
			SELECT  
			UserID,  
			RoleID  
			INTO #tmpUserRole  
			FROM #tmpUserDetailsByRFI  
			WHERE UserID IS NOT NULL  
			AND RoleID IS NOT NULL  
			GROUP BY  
			UserID,  
			RoleID;  

			--select *from #tmpUserRole

			MERGE [UserRole] AS TARGET  
			USING #tmpUserRole AS SOURCE  
			ON (TARGET.UserID = SOURCE.UserID AND TARGET.RoleID=SOURCE.RoleID) 		
			WHEN NOT MATCHED BY TARGET  
			THEN INSERT (UserID, RoleID)  
			VALUES (SOURCE.UserID, SOURCE.RoleID);  
		
		
			DROP TABLE IF EXISTS #tmpUserRole;  
---UserRole Ends



-----Asset Start
			--DROP TABLE IF EXISTS #tmpAssetName;  

			SELECT  
			ISNULL(AssetName,'') as AssetName,  
			ISNULL(AssetDetails,'') as AssetDetails,  
			ISNULL(AssetNote,'') as  AssetNote
			INTO #tmpAssetName  
			FROM #tmpUserDetailsByRFI  
			WHERE ISNULL(AssetName,'')!=''-- IS NOT NULL  
			GROUP BY  
			AssetName,  
			AssetDetails,  
			AssetNote;  

	
		--select *from #tmpAssetName

		MERGE [Asset] AS TARGET  
		USING #tmpAssetName AS SOURCE  
		ON (TARGET.Description = SOURCE.AssetName AND  TARGET.AssetDetails= SOURCE.AssetDetails AND   TARGET.AssetNote= SOURCE.AssetNote)  
		---When records are matched, update the records if there is any change  
		WHEN MATCHED   
		THEN UPDATE SET TARGET.Description = SOURCE.AssetName , TARGET.AssetDetails= SOURCE.AssetDetails , TARGET. AssetNote=SOURCE.AssetNote,TARGET.ModifiedBy=@lUserID,
					ModifiedDt=GETDATE(),TARGET.IsActive=1
		--When no records are matched, insert the incoming records from source table to target table  
		WHEN NOT MATCHED BY TARGET  
		THEN INSERT (Description, AssetDetails, AssetNote, [CreatedBy],	[CreatedDt])  
		VALUES (SOURCE.AssetName, SOURCE.AssetDetails, SOURCE.AssetNote, @lUserID, GETDATE());  
		
	



		UPDATE #tmpUserDetailsByRFI  
		SET #tmpUserDetailsByRFI.AssetID   = B.ID  
		FROM [Asset] B  
		WHERE ISNULL(#tmpUserDetailsByRFI.AssetName,'') = ISNULL(B.Description,'')  AND ISNULL(#tmpUserDetailsByRFI.AssetDetails,'')=ISNULL(B.AssetDetails,'') 
		AND ISNULL(#tmpUserDetailsByRFI.AssetNote,'')=ISNULL(B.AssetNote,'')
		AND #tmpUserDetailsByRFI.AssetID IS NULL;  

		DROP TABLE IF EXISTS #tmpAssetName;  
---Asset End 
--User Asset Start

			DROP TABLE IF EXISTS #tmpUserAsset;  

			SELECT  
			UserID,  
			AssetID  
			INTO #tmpUserAsset  
			FROM #tmpUserDetailsByRFI  
			WHERE UserID IS NOT NULL  
			AND AssetID IS NOT NULL  
			GROUP BY  
			UserID,  
			AssetID;  



			MERGE [UserAsset] AS TARGET  
			USING #tmpUserAsset AS SOURCE  
			ON (TARGET.UserID = SOURCE.UserID)-- AND TARGET.AssetID = SOURCE.AssetID)  
			WHEN MATCHED   
				THEN UPDATE SET TARGET.UserID=SOURCE.UserID,TARGET.AssetID= SOURCE.AssetID,AssignDt=GETDATE()
			WHEN NOT MATCHED BY TARGET  
			THEN INSERT (UserID, AssetID, AssignDt)  
			VALUES (SOURCE.UserID,SOURCE.AssetID, GETDATE());  
------UserAsset end

--RFIDOCUEMNT USER
			MERGE [RFIDocumentUser] AS TARGET  
			USING #tmpUserDetailsByRFI AS SOURCE  
			ON (TARGET.DocumentId = SOURCE.RFDDocid AND TARGET.UserID = SOURCE.UserID)  			
			WHEN NOT MATCHED BY TARGET  
			THEN INSERT (DocumentId,UserId,CreatedBy,CreatedDt)  
			VALUES (SOURCE.RFDDocid,SOURCE.UserID,@lUserID, GETDATE()); 

	EXEC Dbo.UpdateUserDetailsbyWorkday @RFIID   --US_222 --update userdetails from Workday

	IF  NOT EXISTS (select 1 from DocumentDocStatus D ,DocStatus S where D.DocumentID=@lDocumentID and S.[Description]   = 'Success' AND D.DocStatusID=S.ID AND S.IsActive =1 ) --Hari added this condition
	BEGIN

	UPDATE [dbo].[DocumentDocStatus]  
	SET [IsActive] = 0  
	WHERE [DocumentID] = @lDocumentID;  

	END;


	declare @docsuccess int
SELECT @docsuccess =ID FROM [dbo].[DocStatus]  WHERE [Description] = 'Success'  AND [IsActive] = 1  
--UPDATE [dbo].[DocumentDocStatus]  SET [IsActive] = 0  WHERE [DocumentID] = @lDocumentID;
IF EXISTS(SELECT 1 FROM dbo.DocumentDocStatus  WHERE DocumentID= @DocumentID AND DocStatusID=@docsuccess)
BEGIN
UPDATE [dbo].[DocumentDocStatus]  SET [IsActive] = 1  WHERE [DocumentID] = @lDocumentID  AND DocStatusID=@docsuccess
END
ELSE
BEGIN
INSERT INTO [dbo].[DocumentDocStatus]  (  [DocumentID], [DocStatusID]  ,[IsActive])  
SELECT  @lDocumentID,  @docsuccess  ,1

END
			
				
				DROP TABLE IF EXISTS #tmpUserAsset;  
				DROP TABLE IF EXISTS #tmpUserDetailsByRFI;  
				

COMMIT TRANSACTION;  
RETURN 1;  

END TRY  
-- Executable Section END  
-- Exception Handling Section BEGIN  
BEGIN CATCH  
DECLARE @ErrorMessage NVARCHAR(4000);   
DECLARE @ErrorSeverity INT;   
DECLARE @ErrorState INT;   
IF @@TRANCOUNT > 0  
ROLLBACK TRANSACTION;  
UPDATE [dbo].[DocumentDocStatus]  SET [IsActive] = 0  WHERE [DocumentID] = @lDocumentID;

declare @docfailed int
SELECT @docfailed =ID FROM [dbo].[DocStatus]  WHERE [Description] = 'Failed'  AND [IsActive] = 1  

IF EXISTS(SELECT 1 FROM dbo.DocumentDocStatus  WHERE DocumentID= @DocumentID AND DocStatusID=@docfailed)
BEGIN

UPDATE [dbo].[DocumentDocStatus]  SET [IsActive] = 1  WHERE [DocumentID] = @lDocumentID  AND DocStatusID=@docfailed
END
ELSE
BEGIN

INSERT INTO [dbo].[DocumentDocStatus]  (  [DocumentID], [DocStatusID]  ,[IsActive])  
SELECT  @lDocumentID,  @docfailed  ,1

END

SELECT   
@ErrorMessage = ERROR_MESSAGE(),   
@ErrorSeverity = ERROR_SEVERITY(),   
@ErrorState = ERROR_STATE();   
   
-- Use RAISERROR inside the CATCH block to return error   
-- information about the original error that caused   
-- execution to jump to the CATCH block.   
RAISERROR (  
@ErrorMessage, -- Message text.   
 @ErrorSeverity, -- Severity.   
 @ErrorState -- State.   
);  
RETURN 0;  
END CATCH;  
-- Exception Handling Section END  
END;  
GO
/****** Object:  StoredProcedure [dbo].[SaveRFDDocuments]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    PROCEDURE [dbo].[SaveRFDDocuments]
@Stream_Id UNIQUEIDENTIFIER, 
@File_Stream VARBINARY(max),
@Name NVARCHAR(255),
@Is_Archive BIT,
@DocumentCategoryId INT,
@DocumentPath  VARCHAR(500),
@RFITrackingId      VARCHAR(50), -- RFI-1234
@RFDOwner   VARCHAR(50) -- 
AS
BEGIN

DECLARE @DocStatusId INT
DECLARE @RFDID BIGINT
DECLARE @UserID BIGINT


SELECT @RFDID = ID FROM  dbo.RFI WHERE RFITrackingID = @RFITrackingId


SELECT @DocStatusId =  ID FROM Docstatus WHERE [Description] = 'Uploaded';


SELECT @UserID = ID FROM dbo.[User] WHERE UserName = @RFDOwner;

IF (ISNULL(@UserID,0) = 0)
BEGIN
SELECT @UserID = ID FROM dbo.[User] WHERE UserName = 'AMPUser';
END


BEGIN TRY

INSERT INTO FTAmpdocuments (stream_id,file_stream,[name],is_archive) 

VALUES ( @Stream_Id,  @File_Stream,@Name,@Is_Archive) 


INSERT INTO Document(ID,[Description],DocumentPath,DocumentTypeID,IsActive,CreatedBy,CreatedDt)
VALUES(@Stream_Id,@Name,@DocumentPath,@DocumentCategoryId,1,@UserID,GETDATE())


INSERT INTO RFIDocument ([RFIID], [DocumentID], [AssignDt]) VALUES( @RFDID,@Stream_Id,GETDATE());


INSERT INTO DocumentDocStatus (DocumentID,DocStatusID,IsActive)
VALUES(@Stream_Id,@DocStatusId,1)


END TRY

-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END

END
GO
/****** Object:  StoredProcedure [dbo].[SaveRFIListforDelegate]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 11/11/2021
-- Description: dbo.SaveRFIListforDelegate
-- Purpose :Add/Edit rfilist fo delegate
--EXEC SaveRFIListforDelegate '251,252' ,133543,0
 =========================================================

*/


CREATE   PROC [dbo].[SaveRFIListforDelegate] 
(
 @rfiList varchar(100),
 @delegateid bigint ,
 @loginuserid bigint
)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY

DECLARE @Lname varchar(250)
DECLARE @fname varchar(250)
DECLARE @lanid varchar(250)
DECLARE @email varchar(100)

IF(ISNULL(@loginuserid,0) =0)
BEGIN
SELECT @loginuserid=ID FROM dbo.[USER] WHERE  [UserName]='AMPUser'
END

select @Lname=LName,@fname=FName,@lanid=UserName ,@email =Email  from dbo.[User] WHERE ID=@delegateid 

IF (SELECT COUNT(*) FROM DBo.RFIDelegate WHERE DelegateUserID=@delegateid)>0
BEGIN

DELETE FROM DBo.RFIDelegate wHERE [DelegateUserID]=@delegateid
--print'came delete'

END

INSERT INTO dbo.RFIDelegate([RFIID], [Lname], [Fname], [LanId], [EmailId], [DelegateUserID], [IsActive], [CreatedBy], [CreatedDt])
select  cast([value] as bigint) as ID ,@Lname ,@fname ,@lanid ,@email ,@delegateid ,1,@loginuserid,GETDATE ()from STRING_SPLIT (@rfiList, ',') 



END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = 'SaveRFIListforDelegate-proc' +ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
return 1
END
GO
/****** Object:  StoredProcedure [dbo].[UpdateDocumentStatus]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[UpdateDocumentStatus]
@DocumentId UNIQUEIDENTIFIER
AS
BEGIN

BEGIN TRY

UPDATE DocumentDocStatus
SET DocStatusID = ( SELECT ID FROM dbo.DocStatus WHERE  DESCRIPTION ='Failed' AND  IsActive =1)
WHERE DocumentID = @DocumentId AND IsActive = 1;


END TRY

-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END

END
GO
/****** Object:  StoredProcedure [dbo].[UpdateRFIStatusLog]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[UpdateRFIStatusLog]
@rfdId bigint,
@rfiStatus varchar(150),
@loginUserId bigint
AS
BEGIN

BEGIN TRY

DECLARE @rfiStatusId BIGINT

SELECT @rfiStatusId = id FROM RFIStatus WHERE [Description] = @rfiStatus

UPDATE RFIStatuslog SET IsActive = 0, ModifiedBy = @loginUserId, ModifiedDt = GETDATE()  WHERE RFIID = @rfdId

IF EXISTS(SELECT 1 FROM RFIStatuslog  WHERE RFIID = @rfdId AND RFIStatusID IN (@rfiStatusId))
BEGIN
	UPDATE RFIStatuslog SET IsActive = 1 , ModifiedBy = @loginUserId, ModifiedDt = GETDATE() WHERE RFIID = @rfdId AND RFIStatusID IN (@rfiStatusId)
END
ELSE
BEGIN
	INSERT INTO RFIStatuslog(rfiid,RFIStatusID,IsActive,CreatedBy,CreatedDt,ModifiedBy,ModifiedDt)
	values(@rfdId,@rfiStatusId,1,@loginUserId,getdate(),@loginUserId,getdate())
END


END TRY

-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END

END

GO
/****** Object:  StoredProcedure [dbo].[UpdateUserDetailsbyWorkday]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


/* ========================================================
-- Author: Krrishnajayanthi
-- Create Date: 11/11/2021
-- Description: dbo.dbo.UpdateUserDetailsbyWorkday
-- Purpose :Update each  Userdetails  from workday
--EXEC UpdateUserDetailsbyWorkday 131
 =========================================================

*/


CREATE     PROC [dbo].[UpdateUserDetailsbyWorkday] 
(
 @rfiid BIGINT
)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY

declare @applicationid int
declare @currentcampaignid bigint

select @applicationid=ApplicationID  From dbo.[RFIApplication] WHERE RFIID =236 
SELECT @currentcampaignid=[CampaignID]  FROM  [dbo].[Campaignperiod]WHERE Convert(Datetime,getdate(),101)  between [StartDt] AND [EndDt]


DROP TABLE IF EXISTS #tempPastcampaign;  

----US32:GET User details from Past campaign when same username,firstname,lastnmae,email,and empiid not null
SELECT * INTO #tempPastcampaign FROM (
SELECT U1.ID,U2.EmpID,U2.Email ,ROW_Number () OVER (PARTITION BY U1.UserName ORDER BY C.FYID DESC,C.FQID DESC) as rank1
FROM dbo.[user] U1
JOIN dbo.[UserRFI] UR1 ON UR1.RFIID =@rfiid AND UR1.UserID =U1.ID  AND U1.IsActive =1 AND ISNULL(U1.EmpID,0)=0 
JOIN dbo.[RFIApplication] RA on RA.RFIID =UR1.RFIID AND  RA.ApplicationID =@applicationid 
JOIN dbo.RFICampaign RC ON RC.RFIID <>RA.RFIID 
JOIN dbo.Campaign C ON C.Id =RC.CampaignID AND C.IsActive =1
JOIN dbo.RFIStatusLog RSL ON RSL.RFIID =RC.RFIID AND RSL.IsActive =1
JOIN dbo.RFIStatus RS ON RS.ID =RSL.RFIStatusID AND RS.IsActive =1 AND RS.[Description] IN ('Complete/Certification started','Submitted/Pending Acceptance') 
JOIN dbo.[UserRFI] UR2 ON UR2.RFIID =RC.RFIID 
JOIN dbo.[User] U2 ON U2.ID=UR2.UserID AND U2.IsActive =1 AND U2.UserName =U1.UserName and U2.FName =U1.FName AND U2.LName =U1.LName 
											AND RTRIM(LTRIM(ISNULL(ISNULL(U1.Email,U2.Email),'')))=RTRIM(LTRIM(ISNULL(U2.Email,'')))
											AND ISNULL(U2.EmpID ,0)>0 AND ISNULL(U2.ErrorMessage,'') =''
)X  WHERE X.rank1=1

--select *from #tempPastcampaign

UPDATE  U
SET U.EmpID =T.EmpID ,U.Email =T.Email 
FROM dbo.[User] U
JOIN #tempPastcampaign T ON T.ID =U.ID  

SELECT * INTO #temppastCampaigFN FROM (
SELECT U1.ID,U2.EmpID,U2.Email ,ROW_Number () OVER (PARTITION BY U1.UserName ORDER BY C.FYID DESC,C.FQID DESC) as rank1
FROM dbo.[user] U1
JOIN dbo.[UserRFI] UR1 ON UR1.RFIID =@rfiid AND UR1.UserID =U1.ID  AND U1.IsActive =1 AND ISNULL(U1.EmpID,0)=0 
JOIN dbo.[RFIApplication] RA on RA.RFIID =UR1.RFIID AND  RA.ApplicationID =@applicationid 
JOIN dbo.RFICampaign RC ON RC.RFIID <>RA.RFIID 
JOIN dbo.Campaign C ON C.Id =RC.CampaignID AND C.IsActive =1
JOIN dbo.RFIStatusLog RSL ON RSL.RFIID =RC.RFIID AND RSL.IsActive =1
JOIN dbo.RFIStatus RS ON RS.ID =RSL.RFIStatusID AND RS.IsActive =1 AND RS.[Description] IN ('Complete/Certification started','Submitted/Pending Acceptance') 
JOIN dbo.[UserRFI] UR2 ON UR2.RFIID =RC.RFIID 
JOIN dbo.[User] U2 ON U2.ID=UR2.UserID AND U2.IsActive =1  and U2.FName =U1.FName AND U2.LName =U1.LName 
	AND 1=(SELECT COUNT(*) FROM dbo.[UserRFI] UR3 JOIN dbo.[User] U3 ON UR3.RFIID=UR2.RFIID AND U3.Id=UR3.UserID AND U3.ISActive=1
						AND U3.Fname=U2.FName AND U3.Lname=U2.LName AND  RTRIM(LTRIM(ISNULL(U1.Email,U3.Email)))=RTRIM(LTRIM(U3.Email)) )
	AND RTRIM(LTRIM(ISNULL(ISNULL(U1.Email,U2.Email),'')))=RTRIM(LTRIM(ISNULL(U2.Email,'')))
	AND ISNULL(U2.EmpID ,0)>0 AND ISNULL(U2.ErrorMessage,'') =''
	)X  WHERE X.rank1=1

UPDATE  U
SET U.EmpID =T.EmpID ,U.Email =T.Email 
FROM dbo.[User] U
JOIN #temppastCampaigFN T ON T.ID =U.ID  

--- (U.FName =W.HRFirstName AND U.LName =W.HRLastName ) AND U.EmpID IS NULL AND U.TermedDate IS NULL AND U.Email  IS NULL
--group-by username count=1 workday data 

Update U SET
U.EmpID =W.HREmployeeID ,U.Email =W.EmailAddress ,U.TermedDate =W.HRTermDateEffective 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName )
WHERE    ISNULL(U.EmpID,0)=0 AND ISNULL(U.Email,'')=''AND ISNULL(U.TermedDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'   and UR.RFIID=@rfiid
AND EXISTS (SELECT 1 FROM dbo.[User] U1 
	JOIN dbo.UserRFI UR1 ON UR1.UserID =U1.ID AND U1.IsActive =1 
	JOIN dbo.WorkDay W1 ON W1.HRFirstName =U1.FName AND W1.HRLastName =U1.LName 
	WHERE   ISNULL(U1.EmpID,0)=0 AND ISNULL(U1.Email,'')=''AND ISNULL(U.TermedDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'  AND  UR1.RFIID=@rfiid 
	AND U1.UserName =U.UserName 
GROUP BY U1.UserName 
HAVING  count(U1.Username)=1 
)


 -- update termdate ,empid from WorkDay --group by username count=1--termdate and employeeid
 --(U.FName =W.HRFirstName AND U.LName =W.HRLastName ) AND U.EmpID IS NULL  AND U.TermedDate IS NULL AND U.Email =W.HREmialid

Update U SET
U.EmpID =W.HREmployeeID ,U.TermedDate =W.HRTermDateEffective 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName )
WHERE    ISNULL(U.EmpID,0)=0 AND ISNULL(U.Email,'')=''AND U.TermedDate IS NULL   and UR.RFIID=@rfiid
AND EXISTS (SELECT 1 FROM dbo.[User] U1 
	JOIN dbo.UserRFI UR1 ON UR1.UserID =U1.ID AND U1.IsActive =1 
	JOIN dbo.WorkDay W1 ON W1.HRFirstName =U1.FName AND W1.HRLastName =U1.LName 
	WHERE  ISNULL(U.EmpID,0)=0 AND ISNULL(U1.Email,'')=''AND ISNULL(U.TermedDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'  and UR1.RFIID=@rfiid 
	AND U1.UserName =U.UserName 
GROUP BY U1.UserName 
HAVING  count(U1.Username)=1 
)

 -- -- update empid ,email from WorkDay group by username count=1
 ---(U.FName =W.HRFirstName AND U.LName =W.HRLastName ) AND U.EmpID IS NULL  AND U.Email  IS NULL  AND U.termdate=W.termdate

Update U SET
U.EmpID =W.HREmployeeID ,U.Email =W.EmailAddress 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName )
WHERE   ISNULL(U.EmpID,0)=0 AND ISNULL(U.Email,'')=''AND U.TermedDate =W.HRTermDateEffective  and UR.RFIID=@rfiid
AND EXISTS (SELECT 1 FROM dbo.[User] U1 
	JOIN dbo.UserRFI UR1 ON UR1.UserID =U1.ID AND U1.IsActive =1 
	JOIN dbo.WorkDay W1 ON W1.HRFirstName =U1.FName AND W1.HRLastName =U1.LName 
	WHERE ISNULL(U1.EmpID,0)=0 AND ISNULL(U1.Email,'')=''AND U1.TermedDate=W1.HRTermDateEffective  and UR1.RFIID=@rfiid 
	AND U1.UserName =U.UserName 
GROUP BY U1.UserName 
HAVING  count(U1.Username)=1 
)

-- update empid  from WorkDay group by username count=1
--(U.FName =W.HRFirstName AND U.LName =W.HRLastName ) AND U.EmpID IS NULL  AND U.Email  =W.hremail  AND U.termdate=W.termdate


Update U SET
U.EmpID =W.HREmployeeID 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName )
WHERE   ISNULL(U.EmpID,0)=0 AND ISNULL(U.Email,'')=''AND U.TermedDate =W.HRTermDateEffective  and UR.RFIID=@rfiid
AND EXISTS (SELECT 1 FROM dbo.[User] U1 
	JOIN dbo.UserRFI UR1 ON UR1.UserID =U1.ID AND U1.IsActive =1 
	JOIN dbo.WorkDay W1 ON W1.HRFirstName =U1.FName AND W1.HRLastName =U1.LName 
	WHERE   ISNULL(U1.EmpID,0)=0 AND ISNULL(U1.Email,'')=''AND U1.TermedDate=W.HRTermDateEffective and UR1.RFIID=@rfiid 
	AND U1.UserName =U.UserName 
GROUP BY U1.UserName 
HAVING  count(U1.Username)=1 
)

 -- update termdate ,email from WorkDay 
 --(U.FName =W.HRFirstName AND U.LName =W.HRLastName ) AND U.EmpID =W.HREmpoyeeid AND U.TermedDate IS NULL AND U.Email  IS NULL
Update U SET
U.Email =W.EmailAddress ,U.TermedDate =W.HRTermDateEffective 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName ) AND ISNULL(U.EmpID,0) =W.HREmployeeID 
WHERE  UR.RFIID=@rfiid AND ISNULL(U.EmpID,0)=0 AND  ISNULL(U.TermedDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
--AND U.Email IS NULL AND U.TermedDate IS NULL

--update

Update U SET
U.TermedDate =W.HRTermDateEffective ,U.EmpID =W.HREmployeeID 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName ) AND ISNULL(U.EmpID,0) =0 AND RTRIM(LTRIM(U.Email)) =W.EmailAddress 
WHERE  UR.RFIID=@rfiid AND ISNULL(U.TermedDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'


-- update termdate ,  from WorkDay 
--(U.FName =W.HRFirstName AND U.LName =W.HRLastNam e ) AND U.EmpID =W.HREmpoyeeid AND U.TermedDate IS NULL AND U.Email =w.HREmail 
Update U SET
U.TermedDate =W.HRTermDateEffective 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName ) AND U.EmpID =W.HREmployeeID AND RTRIM(LTRIM(U.Email)) =W.EmailAddress 
WHERE  UR.RFIID=@rfiid AND ISNULL(U.TermedDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'

 -- update email from WorkDay 
 --(U.FName =W.HRFirstName AND U.LName =W.HRLastName ) AND U.EmpID =W.HREmpoyeeid AND U.TermedDate= W.termdate AND U.Email  IS NULL

 Update U SET
U.Email =W.EmailAddress 
FROM dbo.[User] U 
JOIN dbo.[UserRFI]  UR ON UR.UserID =U.ID and U.IsActive =1
JOIN dbo.[WorkDay] W ON (W.HRFirstName =U.FName  AND  W.HRLastName =U.LName ) AND ISNULL(U.EmpID,0) =W.HREmployeeID  AND U.TermedDate =W.HRTermDateEffective 
WHERE UR.RFIID=@rfiid AND  ISNULL(U.Email,'')=''--U.Email IS NULL



END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = 'UpdateUserdetailsbyworkdayproc' +ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
return 1
END
GO
/****** Object:  StoredProcedure [dbo].[ValidateUserList]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* ========================================================
-- Author: Krrishnajayanthi and Bramha
-- Create Date: 10/12/2021
-- Description: validate UserList data for each RFIID.if any validation error  1 will be returned ,ifany sp issue -1,
-- Update Date:10/13/2021
-- Update by: Krrishnajayanthi
-- Update description: added validation message for mandatory columns and modifiedby and modified date for all update statement
---EXEC [dbo].[ValidateUserList] 1221,NULL
 =========================================================
*/

CREATE     PROC [dbo].[ValidateUserList] 
(
 @rfdid BIGINT ,
 @returnval int Output
)
AS
BEGIN-- Executable Section BEGIN 


BEGIN TRY
Begin Transaction	
declare @LocalRFIID bigint
declare @rfistatusid int
DECLARE @createdUserid bigint
declare @Ismandatoryvalid int
declare @validationUsermsg varchar(1000)
declare @updatecount int
declare @rfirejecttypeid int 
declare @rficomments varchar(500)
SET @returnval=0
set @Ismandatoryvalid=0
SET @validationUsermsg=''
set @updatecount=0
SELECT @createdUserid=ID FROM dbo.[USER] WHERE  [UserName]='AMPUser'

SET @LocalRFIID=@rfdid

UPDATE U
SET U.ErrorMessage=''
,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID
WHERE UR.RFIID=@LocalRFIID

UPDATE R
SET R.ErrorMessage=''
,R.ModifiedBy=@createdUserid,R.ModifiedDt=GETDATE()
FROM
dbo.UserRFI UR							
	INNER JOIN [dbo].[UserRole] UR1 ON UR1.UserId=UR.UserID
	INNER JOIN [dbo].[Role] R ON R.Id=UR1.Roleid
WHERE UR.RFIID=@LocalRFIID 

UPDATE A
SET A.ErrorMessage=''
,A.ModifiedBy=@createdUserid,A.ModifiedDt=GETDATE()
FROM
dbo.UserRFI UR
INNER JOIN [dbo].[UserAsset] UA ON UA.UserID=UR.UserID
INNER JOIN [dbo].[Asset] A ON A.ID=UA.AssetID	
WHERE UR.RFIID=@LocalRFIID 



--US_24 Check Mandatory Columns Firstname,LastName,Role
				IF (Select   Count(DISTINCT U.Id)
				FROM dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID	  AND U.IsActive=1
								INNER JOIN [dbo].[UserRole] UR1 ON UR1.UserId=U.ID
								INNER JOIN [dbo].[Role] R ON R.Id=UR1.Roleid  AND R.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.Fname,'')='' OR ISNULL(U.Lname,'')='' OR ISNULL(R.Description,'')='')
								AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 
								)>0
				BEGIN

								SET @validationUsermsg='Firstname cannot be blank'
								UPDATE U
								SET U.ErrorMessage= @validationUsermsg,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
								FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.Fname,'')='')
								AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin)


								SET @validationUsermsg='Lastname cannot be blank'
								UPDATE U
								SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
								,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
								FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.Lname,'')='')
								AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin)


								SET @validationUsermsg='Role cannot be blank'
								UPDATE R
								SET R.ErrorMessage= @validationUsermsg ,R.ModifiedBy=@createdUserid,R.ModifiedDt=GETDATE()
								FROM
								dbo.UserRFI UR
									INNER JOIN [dbo].[UserRole] UR1 ON UR1.UserId=UR.UserID
									INNER JOIN [dbo].[Role] R ON R.Id=UR1.Roleid  AND R.IsActive=1
									WHERE ISNULL(R.Description,'')='' AND UR.RFIID=@LocalRFIID
									AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin) 
								
							 SELECT @rfistatusid=Id FROM dbo.[RFIStatus]WHERE [Description] ='Returned' AND IsActive =1
							 SELECT @rficomments = CAST(FORMAT (getdate(), 'dd/MM/yyyy') as varchar(10)) + ' - Firstname/Lastname/Role is missing for some users'
							 SELECT @createdUserid=ID FROM dbo.[USER] WHERE  [UserName]='AMPUser'

							IF  EXISTS(SELECT *FROM dbo.RejectType WHERE [Description]='Not Enough Data Sent')
							BEGIN

							SELECT @rfirejecttypeid= ID  FROM  dbo.RejectType WHERE [Description]='Not Enough Data Sent'
								
							END
							ELSE
							BEGIN
								INSERT INTO dbo.RejectType([Description], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt])
								VALUES('Not Enough Data Sent',1,@createdUserid,getdate(),NULL,NULL)
								SET @rfirejecttypeid=Scope_Identity()
							END

						

							SET @Ismandatoryvalid=1
							SET @returnval=1
							UPDATE RFIStatusLog SET IsActive=0,[ModifiedBy]=@createdUserid, [ModifiedDt]=GetDate() WHERE [RFIID]=@LocalRFIID 		
							IF NOT  EXISTS (SELECT * FROM RFIStatusLog WHERE [RFIID]=@LocalRFIID and  [RFIStatusID]=@rfistatusid)
							BEGIN		
							
								INSERT INTO dbo.RFIStatusLog([RFIID], [RFIStatusID], [IsActive], [CreatedBy], [CreatedDt], [ModifiedBy], [ModifiedDt],RejectTypeid,Comments)
								VALUES( @LocalRFIID,@rfistatusid,1,@createdUserid,getdate(),NULL,NULL,@rfirejecttypeid,@rficomments)

							END	
							ELSE 
							BEGIN
							
							UPDATE RFIStatusLog SET IsActive=1,[ModifiedBy]=@createdUserid, [ModifiedDt]=GetDate() WHERE [RFIID]=@LocalRFIID and  [RFIStatusID]=@rfistatusid

							END
							

					
					END	
						--US---25---validate Firstname and Lastname

						--Check blanks exist for Firstname and Lastname
						
						IF(@Ismandatoryvalid=0)
						BEGIN
											
						--Check No Numbers in firstname nand lastname
						--SELECT * FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID
						--WHERE (ISNULL(U.Fname ,'') LIKE '%[0-9]%'  OR ISNULL(U.Lname ,'')  LIKE '%[0-9]%' )
					
							

									IF (SELECT count(U.ID)FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
									WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.Fname ,'') LIKE '%[0-9]%' )
									AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 
									)>0
									BEGIN

									SET @validationUsermsg='Firstname cannot have numeric characters'
						
									UPDATE U
									SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
									,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
									FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
									WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.Fname ,'') LIKE '%[0-9]%' ) 
									AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 

						            set @updatecount = @updatecount + @@ROWCOUNT
									END


									--Lastname numerics

									IF (SELECT count(U.ID)FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
									WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.Lname ,'')  LIKE '%[0-9]%' )
									AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 
									)>0
									BEGIN

									SET @validationUsermsg='Lastname cannot have numeric characters'
						
									UPDATE U
								SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
									,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
									FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
									WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.Lname ,'')  LIKE '%[0-9]%' ) 
						AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 

						            set @updatecount = @updatecount + @@ROWCOUNT
									END

						
						--Check No special characters other than hyphens or apostrophes
						--SELECT* FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID
						--WHERE UR.RFIID=@LocalRFIID ((U.Fname   LIKE  '%[a-zA-Z\s]%') AND (U.Fname   LIKE  '%[0-9]%') AND (U.Fname  NOT LIKE '%'+CHAR(45)+'%' ) AND   (U.Fname  NOT LIKE '%'+CHAR(39)+'%') )
						--OR ((U.Lname   LIKE  '%[a-zA-Z\s]%') aND (U.Lname   LIKE  '%[0-9]%') AND (U.Lname  NOT LIKE '%'+CHAR(45)+'%' ) AND   (U.Lname  NOT LIKE '%'+CHAR(39)+'%') )

						IF (SELECT count(U.ID)FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND ((U.Fname  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'}))
										--OR (U.LName  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'}))
								AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 			)>0
								BEGIN

								SET @validationUsermsg='Firstname cannot have special characters'
										
								UPDATE U
								SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
								,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
								FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND ((U.Fname  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'}))
										--OR (U.LName  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'}))
								AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 	

						        set @updatecount = @updatecount + @@ROWCOUNT
								END
								--chekc special charcter for Lastname
									IF (SELECT count(U.ID)FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND --((U.Fname  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'})
										 (U.LName  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'})
								AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 			)>0
								BEGIN

								SET @validationUsermsg='Lastname cannot have special characters'
										
								UPDATE U
								SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
								,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
								FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND --- ((U.Fname  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'})
										 (U.LName  LIKE '%[!#%&+,./:;<=>@`{|}~"()*\\\_\^\?\[\]]%' {ESCAPE '\'})
								AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 	

						        set @updatecount = @updatecount + @@ROWCOUNT
								END

					---FirstName diacritics
							DROP TABLE IF EXISTS #tempDicFname
							
								SELECT DISTINCT U.ID,U.Fname,CASE WHEN (select count(*) FROM dbo.Find_Unicode(U.Fname))>0 THEN 1 ELSE 0 END AS [Diacritics]
								INTO #tempDicFname
								FROM	dbo.UserRFI UR WITH (READUNCOMMITTED)	
								INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE  UR.RFIID=@LocalRFIID AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin)

								IF(SELECT Count(*)FROM #tempDicFname WHERE [Diacritics]>0)>0				
								BEGIN

								SET @validationUsermsg='Firstname cannot have diacritics'
										
								UPDATE U
								SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
								,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
								FROM	 dbo.[User] U	INNER JOIN #tempDicFname T ON U.ID=T.ID
								WHERE  T.[Diacritics]>0 AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 	

						        set @updatecount = @updatecount + @@ROWCOUNT


								
								END
						DROP TABLE #tempDicFname
					--Lastname dicatrics
						
					
						DROP TABLE IF EXISTS #tempDicLname

								SELECT DISTINCT U.ID,U.Lname,CASE WHEN (select count(*) FROM dbo.Find_Unicode(U.Lname))>0 THEN 1 ELSE 0 END AS [Diacritics]
								INTO #tempDicLname
								FROM	dbo.UserRFI UR WITH (READUNCOMMITTED)
								INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE  UR.RFIID=@LocalRFIID AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin)

								IF(SELECT Count(*)FROM #tempDicLname WHERE [Diacritics]>0)>0				
								BEGIN

										SET @validationUsermsg='Lastname cannot have diacritics'
										
										UPDATE U
										SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
										,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
										FROM	 dbo.[User] U	INNER JOIN #tempDicLname T ON U.ID=T.ID
										WHERE  T.[Diacritics]>0 AND U.ID NOT IN(SELECT UserID FROM dbo.UserLogin) 	

										set @updatecount = @updatecount + @@ROWCOUNT


								
								END

								DROP TABLE #tempDicLname
								--US---26 Asset ,role							


								--check  Asset cannot  be blank
								IF (SELECT count(A.ID) FROM
										dbo.UserRFI UR	WITH (READUNCOMMITTED)											
											LEFT JOIN [dbo].[UserAsset] UA WITH (READUNCOMMITTED)	 ON UA.UserID=UR.UserID 
											INNER JOIN [dbo].[Asset] A WITH (READUNCOMMITTED)	 ON A.ID=UA.AssetID	 AND A.IsActive=1
										WHERE UR.RFIID=@LocalRFIID AND ISNULL(A.[Description],'')='' 
										 )>0
										BEGIN

								

										SET @validationUsermsg='Asset cannot be blank'

									
										UPDATE A
										SET A.ErrorMessage=@validationUsermsg
										,A.ModifiedBy=@createdUserid,A.ModifiedDt=GETDATE()
										FROM
										dbo.UserRFI UR											
											LEFT JOIN [dbo].[UserAsset] UA ON UA.UserID=UR.UserID
											INNER JOIN [dbo].[Asset] A ON A.ID=UA.AssetID	  AND A.IsActive=1
										WHERE UR.RFIID=@LocalRFIID AND ISNULL(A.[Description],'')='' 

						                set @updatecount = @updatecount + @@ROWCOUNT
								END
							

							--check asset note and details
						IF (SELECT count(A.ID) FROM
										dbo.UserRFI UR WITH (READUNCOMMITTED)	
											INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID	
											LEFT JOIN [dbo].[UserAsset] UA WITH (READUNCOMMITTED)	 ON UA.UserID=U.ID
											INNER JOIN [dbo].[Asset] A WITH (READUNCOMMITTED)	 ON A.ID=UA.AssetID	 AND A.IsActive=1
										WHERE UR.RFIID=@LocalRFIID AND (LEN(A.AssetDetails)>250 OR LEN(A.AssetNote)>250))>0
										BEGIN

							

								SET @validationUsermsg='Asset Detail or Asset Note must be within 250 characters'

									
										UPDATE A
										SET A.ErrorMessage=CASE WHEN ISNULL(A.ErrorMessage,'')<>'' THEN A.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END										,A.ModifiedBy=@createdUserid,A.ModifiedDt=GETDATE()
										FROM
										dbo.UserRFI UR
											INNER JOIN dbo.[User] U ON U.ID=UR.UserID	 AND U.IsActive=1
											LEFT JOIN [dbo].[UserAsset] UA ON UA.UserID=U.ID 
											INNER JOIN [dbo].[Asset] A ON A.ID=UA.AssetID	 AND A.IsActive=1
										WHERE UR.RFIID=@LocalRFIID AND (LEN(A.AssetDetails)>250 OR LEN(A.AssetNote)>250) 

						                set @updatecount = @updatecount + @@ROWCOUNT
								END
							
								--Update Role
								IF (SELECT COUNT(R.ID) FROM 	dbo.UserRFI UR WITH (READUNCOMMITTED)	
									INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID	 AND U.IsActive=1
									INNER JOIN [dbo].[UserRole] UR1 WITH (READUNCOMMITTED)	 ON UR1.UserId=U.ID
									INNER JOIN [dbo].[Role] R WITH (READUNCOMMITTED)	 ON R.Id=UR1.Roleid	 AND R.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND LEN(R.[Description])>250)>0
								BEGIN
								SET @validationUsermsg='Role must be within 250 characters'

								UPDATE R
								SET R.ErrorMessage=@validationUsermsg
								,R.ModifiedBy=@createdUserid,R.ModifiedDt=GETDATE()
								FROM
								dbo.UserRFI UR
									INNER JOIN dbo.[User] U ON U.ID=UR.UserID	 AND U.IsActive=1
									INNER JOIN [dbo].[UserRole] UR1 ON UR1.UserId=U.ID
									INNER JOIN [dbo].[Role] R ON R.Id=UR1.Roleid  AND R.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND LEN(R.[Description])>250

						        set @updatecount = @updatecount + @@ROWCOUNT
								END
						
						--US---27 Employeeid

						--SELECT * FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID
						--WHERE   ISNULL(U.EmpID,0)=0

						
							IF (SELECT COUNT(U.ID) FROM	dbo.UserRFI UR WITH (READUNCOMMITTED)	
										INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID  AND U.IsActive=1
											WHERE UR.RFIID=@LocalRFIID AND  ISNULL(U.EmpID,0)=0 
											AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin WITH (READUNCOMMITTED)	))>0
									BEGIN
									SET @validationUsermsg='EmployeeID cannot be blank'
																		
									UPDATE U
									SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
									,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
									FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
									WHERE UR.RFIID=@LocalRFIID AND ISNULL(U.EmpID,0)=0
									AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin)

						            set @updatecount = @updatecount + @@ROWCOUNT

									END

							
						
										IF EXISTS (SELECT U.ID FROM dbo.UserRFI UR WITH (READUNCOMMITTED)	
													INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID AND U.IsActive=1
													INNER JOIN dbo.WorkDay W WITH (READUNCOMMITTED)	 ON W.HRFirstName=RTRIM(LTRIM(U.Fname)) AND W.HRLastName=RTRIM(LTRIM(U.Lname))
													WHERE UR.RFIID=@LocalRFIID AND ISNULL(U.EmpID,0)=0
													AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin WITH (READUNCOMMITTED)	)  --AND U.ErrorMessage NOT LIKE '%Multiple%'
													GROUP BY U.ID HAVING COUNT(*) > 1)
										BEGIN
										SET @validationUsermsg='Multiple instances of this employee in WorkDay'
									
										UPDATE U
										SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
										,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
										FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive=1
										WHERE UR.RFIID=@LocalRFIID AND ISNULL(U.EmpID,0)=0
										AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin)
										AND 1 < (SELECT COUNT(1) FROM dbo.WorkDay W WHERE W.HRFirstName=RTRIM(LTRIM(U.Fname)) AND W.HRLastName=RTRIM(LTRIM(U.Lname)))

										set @updatecount = @updatecount + @@ROWCOUNT
										END
									--END

						--SELECT count(U.ID) FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID
						--WHERE   LEN(ISNULL(U.EmpID,0))=8
						
								IF (SELECT count(U.ID) FROM	dbo.UserRFI UR	WITH (READUNCOMMITTED)	 INNER JOIN dbo.[User] U  WITH (READUNCOMMITTED)	ON U.ID=UR.UserID AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.EmpID,0)>0 AND U.EmpID >= 100000000 ) AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin))>0
								BEGIN

								SET @validationUsermsg='EmployeeID should have 8 digits'
								UPDATE U
								SET ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
								,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
								FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND (ISNULL(U.EmpID,0)>0 AND  U.EmpID >= 100000000 )
								AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin)

						        set @updatecount = @updatecount + @@ROWCOUNT
						--US---28 Employeeid

						            IF EXISTS (SELECT U.ID FROM dbo.UserRFI UR WITH (READUNCOMMITTED)	
										        INNER JOIN dbo.[User] U  WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID AND U.IsActive=1
										        INNER JOIN dbo.WorkDay W WITH (READUNCOMMITTED)	 ON W.HRFirstName=RTRIM(LTRIM(U.Fname)) AND W.HRLastName=RTRIM(LTRIM(U.Lname))
												WHERE UR.RFIID=@LocalRFIID AND ISNULL(U.EmpID,0)>0 AND U.EmpID >= 100000000
												AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin) --AND U.ErrorMessage NOT LIKE '%Multiple%'
												GROUP BY U.ID HAVING COUNT(*) > 1)
									BEGIN
									SET @validationUsermsg='Multiple instances of this employee in WorkDay'
								
									UPDATE U
									SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
									,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
									FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive=1
									WHERE UR.RFIID=@LocalRFIID AND ISNULL(U.EmpID,0)>0 AND U.EmpID >= 100000000
									AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin)
									AND 1 < (SELECT COUNT(1) FROM dbo.WorkDay W WHERE W.HRFirstName=RTRIM(LTRIM(U.Fname)) AND W.HRLastName=RTRIM(LTRIM(U.Lname)))

									set @updatecount = @updatecount + @@ROWCOUNT
									END
								END

						--US---29 Employeeid
								IF (SELECT count(U.ID) FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID AND U.IsActive=1                 ---count(U.ID)
								WHERE UR.RFIID=@LocalRFIID AND U.EmpID < 100000000 AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin WITH (READUNCOMMITTED)	)
								AND NOT EXISTS (SELECT 1 FROM dbo.WorkDay W WHERE W.HREmployeeID = U.EmpID))>0
								BEGIN
								
								SET @validationUsermsg='EmployeeID not found in WorkDay'
								UPDATE U
								SET ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
								,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
								FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID  AND U.IsActive=1
								WHERE UR.RFIID=@LocalRFIID AND U.EmpID < 100000000
								AND NOT EXISTS (SELECT 1 FROM dbo.WorkDay W WHERE W.HREmployeeID = U.EmpID)
								AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin WITH (READUNCOMMITTED)	)

						        set @updatecount = @updatecount + @@ROWCOUNT
						--US---28 Employeeid

						            IF EXISTS (SELECT U.ID FROM dbo.UserRFI UR WITH (READUNCOMMITTED)	
										        INNER JOIN dbo.[User] U WITH (READUNCOMMITTED)	 ON U.ID=UR.UserID AND U.IsActive=1
										        INNER JOIN dbo.WorkDay W WITH (READUNCOMMITTED)	 ON W.HRFirstName=RTRIM(LTRIM(U.Fname)) AND W.HRLastName=RTRIM(LTRIM(U.Lname))
												WHERE UR.RFIID=@LocalRFIID AND (U.EmpID < 100000000 and U.EmpID >0)
												AND NOT EXISTS (SELECT 1 FROM dbo.WorkDay W2 WITH (READUNCOMMITTED)	 WHERE W2.HREmployeeID = U.EmpID)
												AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin WITH (READUNCOMMITTED)	) ---AND U.ErrorMessage NOT LIKE '%Multiple%'
												GROUP BY U.ID HAVING COUNT(*) > 1)
									BEGIN
									SET @validationUsermsg='Multiple instances of this employee in WorkDay'
								
									UPDATE U
									SET U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
									,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
									FROM	dbo.UserRFI UR	INNER JOIN dbo.[User] U ON U.ID=UR.UserID AND U.IsActive=1
									WHERE UR.RFIID=@LocalRFIID AND U.EmpID < 100000000
									AND NOT EXISTS (SELECT 1 FROM dbo.WorkDay W2 WHERE W2.HREmployeeID = U.EmpID)
									AND UR.UserID NOT IN(SELECT UserID FROM dbo.UserLogin)
									AND 1 < (SELECT COUNT(1) FROM dbo.WorkDay W WHERE W.HRFirstName=RTRIM(LTRIM(U.Fname)) AND W.HRLastName=RTRIM(LTRIM(U.Lname)))

									set @updatecount = @updatecount + @@ROWCOUNT
									END
								END

									IF (
									SELECT count(*) FROM dbo.[User] U WITH (READUNCOMMITTED)						
											INNER JOIN dbo.WorkDay W WITH (READUNCOMMITTED) ON ISNULL(U.EmpID,0)=W.HREmployeeID 											
											WHERE  (W.HRFirstName<>U.Fname OR W.HRLastName<>U.Lname) 
											AND  U.ISActive=1										
											AND U.ID  IN(SELECT UserID FROM dbo.USERRFI WITH (READUNCOMMITTED) WHERE  RFIID=@LocalRFIID)
									)>0	
									BEGIN
									print'4'			

									SET @validationUsermsg='EmployeeID not matching with firstname lastname'
									UPDATE U
									SET  U.ErrorMessage=CASE WHEN ISNULL(U.ErrorMessage,'')<>'' THEN U.ErrorMessage+';'+@validationUsermsg ELSE @validationUsermsg END
									,U.ModifiedBy=@createdUserid,U.ModifiedDt=GETDATE()
									 FROM dbo.[User] U 					
											INNER JOIN dbo.WorkDay W  ON ISNULL(U.EmpID,0)=W.HREmployeeID 											
											WHERE  (W.HRFirstName<>U.Fname OR W.HRLastName<>U.Lname) 
											AND  U.ISActive=1		
											AND U.ID  IN(SELECT UserID FROM dbo.USERRFI WITH (READUNCOMMITTED) WHERE  RFIID=@LocalRFIID)
									set @updatecount = @updatecount + @@ROWCOUNT

									END

						SET @returnval=IIF(@updatecount>0,1,0)	
						END --check mandatory validation issue exists
						
							
				
				--ELSE
				--BEGIN

				--SET @returnval=1
		COMMIT TRANSACTION
END TRY	-- Executable Section END

-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
SELECT 
@ErrorMessage = ERROR_MESSAGE(), 
@ErrorSeverity = ERROR_SEVERITY(), 
@ErrorState = ERROR_STATE(); 
 
-- Use RAISERROR inside the CATCH block to return error 
-- information about the original error that caused 
-- execution to jump to the CATCH block. 
RAISERROR (
@ErrorMessage, -- Message text. 
 @ErrorSeverity, -- Severity. 
 @ErrorState -- State. 
); 
END CATCH;
-- Exception Handling Section END
return @returnval
END

GO
/****** Object:  StoredProcedure [dbo].[ValidateUserwithRFI]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

/* ========================================================
-- Author: Eswara
-- Create Date: 11/10/2021
-- Description: [ValidateUserwithRFI]

--EXEC [ValidateUserwithRFI] 'Brandon Harris','',0
--EXEC [ValidateUserwithRFI] 'f6dfu32','Karayil','08-27-2021'

 ========================================================*/

CREATE   proc [dbo].[ValidateUserwithRFI]
(
@UserName varchar(250) =null
)
AS
BEGIN-- Executable Section BEGIN 
BEGIN TRY
-- Delete validation
SELECT COUNT(1) AS AppCount FROM [User] u, RFIApplication ra
WHERE u.UserName = @UserName AND u.IsActive = 1
AND ra.ApplicationOwnerUserid = u.ID;

END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END

GO
/****** Object:  StoredProcedure [dbo].[ValidateUserWithWorkDay]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


/* ========================================================
-- Author: Hari
-- Create Date: 12/18/2021
-- Description: dbo.ValidateUserWithWorkDay
-- Purpose :Check user exist in workday
--EXEC ValidateUserWithWorkDay 'Ankush','Jain',null
 =========================================================

*/

CREATE     proc [dbo].[ValidateUserWithWorkDay]
(
@FirstName varchar(250),
@LastName varchar(250),
@Email varchar(250)
)
AS
BEGIN-- Executable Section BEGIN 
BEGIN TRY

select count(1) as UserCount from WorkDay  

where  HRFirstName = @FirstName AND HRLastName = @LastName AND EmailAddress = @Email
AND HRTermDateEffective IS NULL

END TRY
-- Executable Section END
-- Exception Handling Section BEGIN
BEGIN CATCH
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
 
	IF @@TRANCOUNT > 0

	SELECT 
	@ErrorMessage = ERROR_MESSAGE(), 
	@ErrorSeverity = ERROR_SEVERITY(), 
	@ErrorState = ERROR_STATE(); 
 
	-- Use RAISERROR inside the CATCH block to return error 
	-- information about the original error that caused 
	-- execution to jump to the CATCH block. 
	RAISERROR (
	@ErrorMessage, -- Message text. 
	 @ErrorSeverity, -- Severity. 
	 @ErrorState -- State. 
	); 
END CATCH;
-- Exception Handling Section END
END
GO
/****** Object:  DdlTrigger [LogObjects]    Script Date: 2/14/2022 7:02:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [LogObjects]
ON DATABASE
FOR CREATE_PROCEDURE,
 ALTER_PROCEDURE,
 DROP_PROCEDURE,
 CREATE_TABLE,
 ALTER_TABLE,
 DROP_TABLE,
 CREATE_FUNCTION,
 ALTER_FUNCTION,
 DROP_FUNCTION,
 CREATE_VIEW,
 ALTER_VIEW,
 DROP_VIEW
AS
SET NOCOUNT ON
DECLARE @data XML
SET @data = EVENTDATA()
INSERT INTO
ChangeActionLog
(
databasename,
eventtype,
objectname,
objecttype,
sqlcommand,
loginname
)
VALUES
(
@data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'varchar(256)'),
@data.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(50)'),
@data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(256)'),
@data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'varchar(25)'),
@data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'varchar(max)'),
@data.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(256)')
)
GO
ENABLE TRIGGER [LogObjects] ON DATABASE
GO
