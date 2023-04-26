-- Query em banco de dados que visa retornar detalhes de chamadas num sistema de telefonia, filtrados por data e regras de banco de dados.

SET NOCOUNT ON 

DECLARE @DATA_INICIO datetime, @DATA_FINAL datetime
Set @DATA_INICIO = '2023-01-01 00:00:00'
Set @DATA_FINAL  = '2023-01-01 23:59:00'

IF OBJECT_ID('tempdb..#Rel_Det_Chamadas') IS NOT NULL
DROP TABLE #Rel_Det_Chamadas

SELECT

CD.service_id as [Campanha], -- CAMPANHA da chamada referente
FORMAT(@CD.CallStartDt, 'dd/MM/yyyy') as [Data Chamada], -- DATA em que se inicia a chamada referente
CD.User_Id as [Operador], -- Operador que responsável pela chamada
dss.Disp_Id, -- Identificação numerica do desfecho da chamada
dss.Disposition_Desc as [Tabulacao] -- Descrição detalhada do desfecho da chamada

INTO #Rel_Det_Chamadas

-- Coleta de dados presentes em diferentes tabelas, para coleta de maior gama de informações, utilizando colunas e filtros em conformidade com a documentação da fabricante
FROM detail_db..CallDetail AS CD WITH(NOLOCK)
LEFT JOIN detail_db..OUTCallDetail      AS OUT with(nolock) on      (CD.SeqNum = AOD.SeqNum AND CD.CallId = AOD.CallId)
LEFT JOIN detail_db..ManualCallDetail   AS MANUAL with(nolock) on (CD.SeqNum = MN.SeqNum AND CD.CallId = MN.CallId)
LEFT JOIN detail_db..MediaDataDetail    AS MEDIA with(nolock) ON   (CD.SeqNum = MDD.SeqNum AND CD.CallId = MDD.CallId)
INNER JOIN config_db..Disposition AS DISP with(nolock) on((dsS.Disp_Id = (CASE WHEN ISNULL(AOD.SwitchDispId,MN.SwitchDispId) NOT IN ('13', '16') THEN ISNULL(AOD.SwitchDispId,MN.SwitchDispId) ELSE ISNULL(AOD.AgentDispId,MN.FirstPartyDispId) END))) 

WHERE CD.User_Id IS NOT NULL -- Ignora linhas de dados onde não há operador responsável (chamadas não atendidas)
AND CD.CallStartDt BETWEEN @DATA_INICIO and @DATA_FINAL 

GROUP BY CD.Service_Id, dss.Disp_Id, dss.Disposition_Desc -- Agrupa principais identificações nos dados para facilitar a visualização

SELECT * FROM #Rel_Det_Chamadas
ORDER BY Campanha -- Ordena dados por identificação de serviço (campanha) após agrupamento de informações