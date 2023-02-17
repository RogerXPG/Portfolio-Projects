-- Query em banco de dados que visa retornar dados ligados a margem de tempo de uso dos operadores, isto é, tempo disponível para atendimento, quantidade de chamadas atendidas e entre outros valores.

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @dataIni VARCHAR(20), @dataFim VARCHAR(20), @NUM_DIA int 
SET @NUM_DIA = 0;

SET @dataIni = CONVERT(VARCHAR(20), GETDATE() -0, 102 ) + ' 03:00:00';
SET @dataFim = CONVERT(VARCHAR(20), GETDATE() -0, 102 ) + ' 23:59:59'; 

IF OBJECT_ID('tempdb..#TEMPLOGINGLOGOUT') IS NOT NULL
DROP TABLE #TEMPLOGINGLOGOUT

IF OBJECT_ID('tempdb..#TEMPATIVO') IS NOT NULL
DROP TABLE #TEMPATIVO

IF OBJECT_ID('tempdb..#TEMPPAUSE') IS NOT NULL
DROP TABLE #TEMPPAUSE

IF OBJECT_ID('tempdb..#TABELAFINAL') IS NOT NULL
DROP TABLE #TABELAFINAL

--============================== Seleção da tabela "SigInSummary" ==============================--
SELECT

FORMAT(ASS.LoginDt, 'dd/MM/yyyy') as [Data],
ASS.User_Id as [ID do Usuario],
MIN(ASS.LoginDt) as [Login],
MAX(ASS.LogoutDt) as [Logout],
CONVERT(varchar, DATEADD(ms, SUM(ASS.IdleTime) * 1000, 0), 108) as [Tempo Ocioso],
CONVERT(varchar, DATEADD(MS, DATEDIFF(SECOND, MIN(ASS.LoginDt), MAX(ASS.LogoutDt)) * 1000, 0), 108) as [Tempo Logado]
,SUM(ASS.IdleTime) AS [IdleTime]

INTO #TEMPLOGINGLOGOUT

FROM summary_db..AgentSignInSummary AS ASS 

WHERE DATEADD(hour, -3, ASS.LoginDt) BETWEEN @dataIni AND @dataFim

GROUP BY ASS.User_Id
-----------------------------------------------------------------------------------------------------

--============================== Seleção da tabela "MediaAgentSummary" ==============================--
SELECT 
MAS.User_Id as [ID do Usuario], 
SUM(MAS.TotalAgentCalls) as [Qtd Ligacoes Atendidas],
CONVERT(varchar, DATEADD(MS, SUM(MAS.ActiveTime) * 1000, 0), 108) as [Tempo Ativo],

INTO #TEMPATIVO

FROM summary_db..MediaAgentSummary AS MAS WITH (NOLOCK) 

WHERE DATEADD(HOUR, -3, MAS.BeginTimePeriodDt) BETWEEN @dataIni AND @dataFim

GROUP BY MAS.User_Id
-----------------------------------------------------------------------------------------------------

--============================== Seleção da tabela "AgentNotReadySummary" ==============================--
SELECT 
ANR.User_Id as [ID_User], 
CONVERT(varchar, DATEADD(MS, SUM(ANR.NotReadyTime) * 1000, 0), 108) as [Pausa],

INTO #TEMPPAUSE
FROM 
summary_db..AgentNotReadySummary AS ANR WITH (NOLOCK) 
WHERE DATEADD(HOUR, -3, ANR.LoginDt) BETWEEN @dataIni AND @dataFim

GROUP BY ANR.User_Id 
-----------------------------------------------------------------------------------------------------

--============================== Inserção de dados previamentes coletados em tabela final ==============================--
SELECT Convert(varchar(10),dateadd(hour,-3,LL.Data),103) as Data, 
LL.User_Id AS [Usuário],
LL.[Tempo Logado],
ISNULL(ATV.[Qtd Ligacoes Atendidas],0) AS [Qtd Ligações Atendidas], 
LL.[Tempo Ocioso] AS [Ocioso],
TPA.Pausa AS [Pausas],
ISNULL(ATV.[Tempo Ativo],0) AS [Ativo],

INTO #TABELAFINAL

FROM #TEMPLOGINGLOGOUT AS LL
LEFT JOIN #TEMPATIVO AS ATV ON LL.User_Id = ATV.[ID do Usuario]
LEFT JOIN #TEMPPAUSE AS TPA ON LL.User_Id = TPA.[ID_User]

ORDER BY LL.User_Id
-----------------------------------------------------------------------------------------------------------------------------

--============================== Seleção final da query! ==============================--

SELECT * 
FROM #TABELAFINAL 
WHERE [Usuário] != 'admin' -- Ignora os usos de nosso usuário de testes da plataforma, conhecido como "admin"

-- SELECTs para caso haja a necessidade de uma validação rápida das tabelas temporárias criadas
--SELECT * FROM #TEMPLOGINGLOGOUT
--SELECT * FROM #TEMPATIVO
--SELECT * FROM #TEMPPAUSE
--SELECT * FROM #TABELAFINAL