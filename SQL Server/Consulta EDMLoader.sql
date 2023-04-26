-- Query para validar a integridade do banco de dados e o tempo de inserção de novas informações no mesmo
-- Caso os campos "FailedCount", ou "DuplicateCount" estejam com algum valor acima de 0, isso significa que algum problema está acontecendo na inserção de dados, sendo necessária validação de forma urgente na saúde do banco

SELECT TOP 1000 [Site_Id]
      ,[ServerId]
      ,[TenantId]
      ,[FileName]
      ,[FileLoadStartDt]
      ,[FileLoadEndDt]
      ,[FileLoadTimeInSS]
      ,[ProcessedCount]
      ,[FailedCount]
      ,[DuplicateCount]

FROM [detail_epro].[dbo].[EDMLoaderAudit]

WHERE (FailedCount > 0 or DuplicateCount > 0)

ORDER BY FileName DESC
