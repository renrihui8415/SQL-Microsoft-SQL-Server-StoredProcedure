USE [JuliaDatabase]
--select count (OrderID) from [Orders]
--select count(*) from [OrderDetails]

--Create index Idx_Phone ON Shippers (Phone)
--Create index Idx_OrderID ON [OrderDetails] (OrderID)

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.5 Supplier Country, City, Postal Code, Area Code Driven Sales Performance
*/

--select Phone from Suppliers
--Create index Idx_Phone ON Suppliers (Phone)
--Create index Idx_Country ON Suppliers (Country)
--Create index Idx_City ON Suppliers (City)
--Create index Idx_PostalCode ON Suppliers (PostalCode)
select count(Phone) from suppliers where charindex('.',phone)>0 or charindex('-',phone)>0 or charindex('(',phone)>0


USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_ProductsDriven') IS NOT NULL
    DROP PROCEDURE usp_ProductsDriven
GO

CREATE PROCEDURE usp_ProductsDriven(@Country varchar(2000) =null,@City varchar(2000) =null,@PostalCode varchar(2000) =null,@AreaCode_No varchar(2000) =null )
AS
BEGIN

    SET NOCOUNT ON
-----------------------------------------------------------
	declare @count  tinyint =0
	set @count=iif(@Country is null,0,1)+iif(@City is null,0,1)+iif(@PostalCOde is null,0,1)+iif(@AreaCode_No is null,0,1)
	Declare @countCountry tinyint=0
	if @Country is not null
		set @countCountry=1
	Declare @countCity tinyint=0
	if @City is not null
		set @countCity=1
	Declare @countPostalCode tinyint=0
	if @PostalCode is not null
		set @countPostalCode=1
	Declare @countAreaCode tinyint=0
	if @AreaCode_No is not null
		set @countAreaCode=1

	Declare @sql varchar(8000)
	if @count=0 
	set @sql='
select Country, City, PostalCode, AreaCode,format(SalesPerformance, ''C'') as SalesPerformance, RankInPopularity
from (

	Select Country, City, PostalCode, AreaCode,
			SalesPerformance, 
			RANK() OVER (Order by SalesPerformance Desc) RankInPopularity
	from (
			select Country, City, PostalCode, AreaCode, Sum(SalesPerformance) as SalesPerformance
			from (
		
					select Country,City, PostalCode, case when charIndex(''('',phone) >0 and charIndex('')'',phone) >0 then Substring (Phone,Charindex(''('', Phone)+1,Charindex('')'', Phone)-Charindex(''('', Phone)-1)
																   when charindex(''-'',phone)>0 and charindex(''('',Phone)=0  then substring(Phone,1,charindex(''-'',Phone)-1)
																   when charIndex(''.'',phone) >0 then Substring (Phone,1,Charindex(''.'',phone)-1)
																   when charIndex(''('',phone) =0 and charIndex('')'',phone) =0 and  charIndex(''.'',phone) =0 then ''000''
																   end AreaCode, SalesPerformance
					from (

							select SupplierID, sum(isnull(od.unitprice*od.quantity*(1-od.discount),0)) as salesperformance 
							from OrderDetails as od inner join Products as p
							on od.productid=p.productid
							group by SupplierID
							) as t inner join Suppliers as s on t.SupplierID=s.SupplierID
										 
				)as tt Group by Country, City, PostalCode, AreaCode
		) as g
) as h'




	else set @sql='
Select '+ case when @Country is not null then 'Country,' 
				else ' ' end + 
			Case when  @City is not null then 'City,' 
				else ' ' end + 
			case when @PostalCOde is not null then 'PostalCode,' 
				else ' ' end +
			case when @AreaCode_No  is not null then 'AreaCode,' 
				else ' ' end +'
		format (SalesPerformance,''c'') as SalesPerformance, 
		RANK() OVER (Order by SalesPerformance Desc) RankInPopularity
from (
		Select '+ case when @Country is not null then 'Country,' 
						else ' ' end + 
					Case when  @City is not null then 'City,' 
						else ' ' end + 
					case when @PostalCOde is not null then 'PostalCode,' 
						else ' ' end +
					case when @AreaCode_No  is not null then 'AreaCode,' 
						else ' ' end +'
				sum(SalesPerformance) as SalesPerformance 
				
		from (

				select Country,City, PostalCode, case when charIndex(''('',phone) >0 and charIndex('')'',phone) >0 then Substring (Phone,Charindex(''('', Phone)+1,Charindex('')'', Phone)-Charindex(''('', Phone)-1)
															   when charindex(''-'',phone)>0 and charindex(''('',Phone)=0  then substring(Phone,1,charindex(''-'',Phone)-1)
															   when charIndex(''.'',phone) >0 then Substring (Phone,1,Charindex(''.'',phone)-1)
															   when charIndex(''('',phone) =0 and charIndex('')'',phone) =0 and  charIndex(''.'',phone) =0 then ''000''
															   end AreaCode, SalesPerformance
				from (

						select SupplierID, sum(isnull(od.unitprice*od.quantity*(1-od.discount),0)) as salesperformance 
						from OrderDetails as od inner join Products as p
						on od.productid=p.productid
						group by SupplierID
					  ) as t inner join Suppliers as s on t.SupplierID=s.SupplierID
			 )as tt'
		+ case when @count>0 then ' where '
				else ' ' end +

case when @Country is not null and @Country <> 'all' then 
					' Country in ('+ 
						(CONCAT('''',
						REPLACE(@Country, ',', ''','''), '''')) 
						+ ') ' 
				when @Country='all' then ' Country is not null '
				else ' ' end + 

			case when @CountCountry=1 and @CountCity=1 then' and ' 
				when @countcountry=0 and @countcity=1 then ' '
				when @countcountry=1 and @countcity=0 then ' '
				else ' ' end +

			case when @City is not null and @City <> 'all' then 
					' City in ('+ 
						(CONCAT('''',
						REPLACE(@City, ',', ''','''), '''')) 
						+') ' 
				when @City='all'  then ' City is not null ' 
				else ' ' end + 

			case when @countCountry+@countcity >0 and @CountPostalCode=1 then ' and ' 
				when @countCountry+@countcity =0 and @countPostalCode=1 then ' '
				when @countCountry+@countcity >0 and @countPostalCode=0 then ' '
				else ' ' end +

			case when @PostalCode is not null and @PostalCOde <> 'all' then 
						' PostalCode in ('+ 
						(CONCAT('''',
						REPLACE(@PostalCode, ',', ''','''), ''''))  
						+')' 
				when  @PostalCode='all'  then  ' PostalCode is not null '
				else ' ' end +

			case when @count>1 and @countAreaCode =1 then ' and '
				else ' ' end +

			Case when @AreaCode_No is not null and @AreaCode_No <> 'all' Then 'AreaCode in (' + @AreaCode_No + ')'
				when  @AreaCode_No='all'  then   'AreaCode is not null '
				else ' ' end +




		'Group by ' +
		case when @Country is not null and @count>1 then 'Country,' 
			when @Country is not null and @count=1 then 'Country'
			else ' ' end + 
		Case when  @City is not null and @countPostalCode+@countAreaCode>0 then 'City,'
			 when  @City is not null and @countPostalCode+@countAreaCode=0 then 'City'
			else ' ' end + 
		case when @PostalCOde is not null and @countAreaCode > 0 then 'PostalCode,' 
			when @PostalCOde is not null and @countAreaCode = 0 then 'PostalCode' 
			else ' ' end +
		case when @AreaCode_No is not null then 'AreaCode' 
			else ' ' end +'
) as g'
											 
	print @sql
	print @count
	print @Countcountry
	exec(@sql)

    SET NOCOUNT OFF

END
GO
--************************************************************************************************
--to run the SP
exec usp_ProductsDriven null,null,null,null--shows sales performance for all suppliers
exec usp_ProductsDriven 'USA,Canada','Bosto,Bend',"all","617,503" --4 parameters passed in 
exec usp_ProductsDriven "'USA'","all","all","all"
exec usp_ProductsDriven "'USA','Canada'",null,null,null
exec usp_ProductsDriven null,null,null,"all"
exec usp_ProductsDriven "all",null,null,"all"
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.17 Improve 2.5 with Percentile
*/
USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_ProductsDrivenPercentile') IS NOT NULL
    DROP PROCEDURE usp_ProductsDrivenPercentile
GO
if OBJECT_ID('Supplier') is not null 
drop table Supplier
--Create table #Supplier_p (Country varchar(255), City varchar(255), PostalCode varchar(255), Areacode int, SalesPerformance float)
Go
CREATE PROCEDURE usp_ProductsDrivenPercentile(@Percentile tinyint =null,@Country varchar(2000) =null,@City varchar(2000) =null,@PostalCOde varchar(2000) =null,@AreaCode_No varchar(2000) =null )
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON
	--if OBJECT_ID('##Supplier_p') is not null drop table ##Supplier_p
	--select * from ##Supplier_p
-----------------------------------------------------------
	declare @count  tinyint =0
	set @count=iif(@Country is null,0,1)+iif(@City is null,0,1)+iif(@PostalCOde is null,0,1)+iif(@AreaCode_No is null,0,1)
	Declare @countPercentile tinyint=0
	if @Percentile is not null
		set @countPercentile=1
	else set @CountPercentile=0
	Declare @countCountry tinyint=0
	if @Country is not null
		set @countCountry=1
	else set @CountCountry=0
	Declare @countCity tinyint=0
	if @City is not null
		set @countCity=1
	else set @CountCity=0
	Declare @countPostalCode tinyint=0
	if @PostalCode is not null
		set @countPostalCode=1
	else set @CountPostalCode=0
	Declare @countAreaCode tinyint=0
	if @AreaCode_No is not null
		set @countAreaCode=1
	else set @CountAreaCode=0
	
	Declare @sql varchar(8000)
	if @count=0 
	--all columns are null except @percentile
	set @sql='

	select Country, City, PostalCode, AreaCode, Sum(SalesPerformance) as SalesPerformance
	into supplier
	from (
		
			select Country,City, PostalCode, case when charIndex(''('',phone) >0 and charIndex('')'',phone) >0 then Substring (Phone,Charindex(''('', Phone)+1,Charindex('')'', Phone)-Charindex(''('', Phone)-1)
															when charindex(''-'',phone)>0 and charindex(''('',Phone)=0  then substring(Phone,1,charindex(''-'',Phone)-1)
															when charIndex(''.'',phone) >0 then Substring (Phone,1,Charindex(''.'',phone)-1)
															when charIndex(''('',phone) =0 and charIndex('')'',phone) =0 and  charIndex(''.'',phone) =0 then ''000''
															end AreaCode, 
															SalesPerformance
			from (

					select SupplierID, sum(isnull(od.unitprice*od.quantity*(1-od.discount),0)) as salesperformance 
					from OrderDetails as od inner join Products as p
					on od.productid=p.productid
					group by SupplierID

				  ) as t inner join Suppliers as s on t.SupplierID=s.SupplierID
										 
		)as tt Group by Country, City, PostalCode, AreaCode'



    else set @sql='
		Select '+ case when @Country is not null then 'Country,' 
						else ' ' end + 
					Case when  @City is not null then 'City,' 
						else ' ' end + 
					case when @PostalCOde is not null then 'PostalCode,' 
						else ' ' end +
					case when @AreaCode_No  is not null then 'AreaCode,' 
						else ' ' end +'
				sum(SalesPerformance) as SalesPerformance 
		into Supplier		
		from (


				select Country,City, PostalCode, case when charIndex(''('',phone) >0 and charIndex('')'',phone) >0 then Substring (Phone,Charindex(''('', Phone)+1,Charindex('')'', Phone)-Charindex(''('', Phone)-1)
															   when charindex(''-'',phone)>0 and charindex(''('',Phone)=0  then substring(Phone,1,charindex(''-'',Phone)-1)
															   when charIndex(''.'',phone) >0 then Substring (Phone,1,Charindex(''.'',phone)-1)
															   when charIndex(''('',phone) =0 and charIndex('')'',phone) =0 and  charIndex(''.'',phone) =0 then ''000''
															   end AreaCode, SalesPerformance
				from (

						select SupplierID, sum(isnull(od.unitprice*od.quantity*(1-od.discount),0)) as salesperformance 
						from OrderDetails as od inner join Products as p
						on od.productid=p.productid
						group by SupplierID
					  ) as t inner join Suppliers as s on t.SupplierID=s.SupplierID


			 )as tt'
		+ case when @count>0 then ' where '
				else ' ' end +

			case when @Country is not null and @Country <> 'all' then 
					' Country in ('+ 
						(CONCAT('''',
						REPLACE(@Country, ',', ''','''), '''')) 
						+ ') ' 
				when @Country='all' then ' Country is not null '
				else ' ' end + 

			case when @CountCountry=1 and @CountCity=1 then' and ' 
				when @countcountry=0 and @countcity=1 then ' '
				when @countcountry=1 and @countcity=0 then ' '
				else ' ' end +

			case when @City is not null and @City <> 'all' then 
					' City in ('+ 
						(CONCAT('''',
						REPLACE(@City, ',', ''','''), '''')) 
						+') ' 
				when @City='all'  then ' City is not null ' 
				else ' ' end + 

			case when @countCountry+@countcity >0 and @CountPostalCode=1 then ' and ' 
				when @countCountry+@countcity =0 and @countPostalCode=1 then ' '
				when @countCountry+@countcity >0 and @countPostalCode=0 then ' '
				else ' ' end +

			case when @PostalCode is not null and @PostalCOde <> 'all' then 
						' PostalCode in ('+ 
						(CONCAT('''',
						REPLACE(@PostalCode, ',', ''','''), ''''))  
						+')' 
				when  @PostalCode='all'  then  ' PostalCode is not null '
				else ' ' end +

			case when @count>1 and @countAreaCode =1 then ' and '
				else ' ' end +

			Case when @AreaCode_No is not null and @AreaCode_No <> 'all' Then 'AreaCode in (' + @AreaCode_No + ')'
				when  @AreaCode_No='all'  then   'AreaCode is not null '
				else ' ' end +


		' Group by ' +
		case when @Country is not null and @count>1 then 'Country,' 
			when @Country is not null and @count=1 then 'Country'
			else ' ' end + 
		Case when  @City is not null and @countPostalCode+@countAreaCode>0 then 'City, '
			 when  @City is not null and @countPostalCode+@countAreaCode=0 then 'City '
			else ' ' end + 
		case when @PostalCOde is not null and @countAreaCode > 0 then 'PostalCode, ' 
			when @PostalCOde is not null and @countAreaCode = 0 then 'PostalCode ' 
			else ' ' end +
		case when @AreaCode_No is not null then 'AreaCode ' 
			else ' ' end 

											 
	print @sql
	print @count
	
	exec(@sql)

	------------------------------------------------------

	declare @TotalRows as int
	declare @PerRow as decimal(36,2)
	set @TotalRows =( Select Count(*) from Supplier)
	set @PerRow =(@TotalRows+1)*(isnull(@Percentile,0)) /100 

	declare @decimalPart as decimal(36,2)
	set @decimalPart= @PerRow-floor(@PerRow)

	declare @mediaintPart as int
	declare @intPart as int
	Set @mediaintPart=floor(@PerRow)
	if @mediaintPart =0
		set @intPart=1
	else set @intPart=floor(@PerRow)


	declare @Pvalue as decimal(36,2)
	declare @PValue1 as decimal(36,2)
	if @Percentile >0 
		set @Pvalue= (select SalesPerformance from (select * from Supplier
														Order by SalesPerformance
														OFFSET (@intPart-1) ROWS
	 													FETCH NEXT 1 ROW ONLY)as t)
	--else set @Pvalue= (select SalesPerformance from (select * from ##Supplier_p 
														--Order by SalesPerformance
														--OFFSET (@intPart-1) ROWS
	 													--FETCH NEXT 1 ROW ONLY)as t)

	Set @PValue1=(Select SalesPerformance from (Select * from Supplier
													Order by SalesPerformance
													offset (@intPart) rows
													fetch next 1 row only ) as t1)

	declare @Value as decimal(36,2)													
	if @decimalPart=0 set @Value=@Pvalue
	else set @Value=@Pvalue+@decimalPart*(@PValue1-@Pvalue)

	if @mediaintPart=0 
		set @value=0
    --select @TotalRows as TotalRows, @PerRow as PerRow,@intPart as intPart, @decimalPart as DecimailPart, @Pvalue as Pvalue, @PValue1 AS PValue1, @Value as Value
	-----------------------------------------------------------------------------------------------

	declare @string as varchar(200)
	if @Percentile >0 
		set @string = + convert(varchar, @percentile)+ 'th Percentile Value is ' +convert(varchar,@Value)
	
	else set @string='No percentile is set'
	print @string

	Select *,
				RANK() OVER (Order by SalesPerformance Desc) RankInPopularity
	from Supplier
	where SalesPerformance >=@Value

--select * from Supplier

	Drop table Supplier

  SET NOCOUNT OFF

END TRY
BEGIN CATCH
	if OBJECT_ID('Supplier') is not null drop table Supplier
	PRINT(ERROR_MESSAGE())
END CATCH
END
GO
--************************************************************************************************
--to run the SP
exec usp_ProductsDrivenPercentile 0--shows sales performance for all suppliers
exec usp_ProductsDrivenPercentile 0, 'USA,Canada','Bend,Montréal,Bosto',"all","617,503,514" --5 parameters passed in 
exec usp_ProductsDrivenPercentile 50 --shows 50th Percentile value, the median
exec usp_ProductsDrivenPercentile
exec usp_ProductsDrivenPercentile null,null,null,null,617
exec usp_ProductsDrivenPercentile @percentile=0,@country='USA,Canada',
									@city=NULL,@PostalCode=null,
									@AreaCode_No=null
exec usp_ProductsDrivenPercentile @percentile=0,@country='USA,Canada'

exec usp_ProductsDrivenPercentile 0, 'USA,Canada','all',"all","all" --5 parameters passed in 


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.7 Ship Area Code Driven Sales Performance
*/
--select * from Shippers
--create index idx_Shippers_Phone on Shippers(Phone)
--create index idx_Orders_ShipVia on Orders(ShipVia)
USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_ShippingDriven') IS NOT NULL
    DROP PROCEDURE usp_ShippingDriven
GO

CREATE PROCEDURE usp_ShippingDriven(@AreaCode_No varchar(2000) =null )
AS
BEGIN

    SET NOCOUNT ON

	Declare @sql varchar(8000)
    set @sql='
	
	select AreaCode, format(SalesPerformance, ''C'') as SalesPerformance, RankInPopularity 
	from (

		select AreaCode,  SalesPerformance, RANK() OVER (Order by SalesPerformance Desc) RankInPopularity 
		from (
				Select AreaCode, sum(isnull (UnitPrice*Quantity*(1-Discount) ,0) ) as SalesPerformance
				From(

					select OrderID, Substring(phone,2,3) as AreaCode 
					from Shippers as s inner join [Orders] as o 
					On s.ShipperID=o.Shipvia 
					Where '+
					Case when @AreaCode_No is not null and @AreaCode_No <>'all' 
								Then 'Substring (Phone,2,3) in (' + @AreaCode_No + ')'
						 when @AreaCode_No ='all' or @AreaCode_No is null 
								then 'Substring (Phone,2,3) is not null ' end +

					') as t inner join [OrderDetails] as od
						On t.OrderID=od.OrderID
						Group by AreaCode

				) as tt
			) as w
			Order by RankInPopularity'

	print @sql

	exec(@sql)

    SET NOCOUNT OFF

END
GO
--************************************************************************************************
--to run the SP
exec usp_ShippingDriven --sales performance for all Shippers
exec usp_ShippingDriven '901,202,203' --Sales performance for shippers whose phone area code is 901, 202, 203


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.19 Improve 2.7 with Percentile
*/

USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_ShippingDriven_Percentile') IS NOT NULL
    DROP PROCEDURE usp_ShippingDriven_Percentile
GO
if OBJECT_ID('Shipper') is not null 
drop table Shipper
go
CREATE PROCEDURE usp_ShippingDriven_Percentile(@Percentile tinyint =null,@AreaCode_No varchar(2000) =null )
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON
	if OBJECT_ID('Shipper') is not null Drop Table Shipper
	--declare @AreaCode_No varchar(2000),@Percentile tinyint
	
	Declare @sql varchar(8000)
    set @sql='

			Select AreaCode, sum(isnull (UnitPrice*Quantity*(1-Discount) ,0) ) as SalesPerformance
			into Shipper
			From 
				   (
			Select Substring (Phone,2,3) as AreaCode,  OrderID
			from Shippers as s inner join [Orders] as o 
			On s.ShipperID=o.Shipvia 
			Where '+
			Case when @AreaCode_No is not null and @AreaCode_No <>'all'
					Then ' Substring (Phone,2,3) in (' + @AreaCode_No + ')'
				  when @AreaCode_No is null or @AreaCode_No ='all' 
					then' Substring (Phone,2,3) is not null ' end +

		   ') as t inner join [OrderDetails] as od
				On t.OrderID=od.OrderID
				Group by AreaCode  
				'

	print @sql

	exec(@sql)

	--------------------------------------------------------------
	--next is to calculate how many rows is @percentile

	declare @TotalRows as int
	declare @PerRow as decimal(36,2)
	set @TotalRows =( Select Count(*) from Shipper)
	set @PerRow =(@TotalRows+1)*(isnull(@Percentile,0)) /100 

	declare @decimalPart as decimal(36,2)
	set @decimalPart= @PerRow-floor(@PerRow)

	declare @mediaintPart as int
	declare @intPart as int
	Set @mediaintPart=floor(@PerRow)
	if @mediaintPart =0
		set @intPart=1
	else set @intPart=floor(@PerRow)
	

	declare @Pvalue as decimal(35,3) 
	declare @PValue1 as decimal(35,3)
	if @Percentile >0 
		set @Pvalue= (select SalesPerformance from (select * from Shipper 
														Order by 2 
														OFFSET (@intPart-1) ROWS
	 													FETCH NEXT 1 ROW ONLY)as t)
	--else set @Pvalue= (select SalesPerformance from (select * from ##Ship_p 
														--Order by 2 
														--OFFSET (@intPart) ROWS
	 													--FETCH NEXT 1 ROW ONLY)as t)

	Set @PValue1=(Select SalesPerformance from (Select * from Shipper 
													Order by 2 
													offset (@intPart) rows
													fetch next 1 row only ) as t1)

	declare @Value as decimal(35,3)													
	if @decimalPart=0 set @Value=@Pvalue
	else set @Value=@Pvalue+@decimalPart*(@PValue1-@Pvalue)

	if @mediaintPart=0 
	set @value=0

	--select @TotalRows as TotalRows, @PerRow as PerRow,@intPart as intPart, @decimalPart as DecimailPart, @Pvalue as Pvalue, @PValue1 AS PValue1, @Value as Value
	-----------------------------------------------------------------------------------------------
	declare @string as varchar(200)
	if @Percentile >0 
		set @string = + convert(varchar, @percentile)+ 'th Percentile Value is ' +format(@Value,'C')
	
	else set @string='No percentile is set'
	print @string

	Select AreaCode, Format(SalesPerformance,'C') as SalesPerformance, RankInPopularity from (
		Select AreaCode,  SalesPerformance, RANK() OVER (Order by SalesPerformance Desc) RankInPopularity
		from Shipper 
		where SalesPerformance >=@Value
		) as t 


	Drop table Shipper
    SET NOCOUNT OFF
END TRY
BEGIN CATCH
	if OBJECT_ID('Shipper') is not null drop table Shipper
	PRINT(ERROR_MESSAGE())
END CATCH
END
GO
--************************************************************************************************
--to run the SP
exec usp_ShippingDriven_Percentile --if the Client wishes to know SalesPerformance for all AreaCode areas
exec usp_ShippingDriven_Percentile 0,'901,202,203' --if the Client wishes to know some specific AreaCode areas
exec usp_ShippingDriven_Percentile 50 --if the Client wishes to know SalesPerformance equal to and above one certain percentile (eg,50th percentile)



/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.9 Popular Suppliers with products sales performance
*/
--Create index Idx_Shipvia ON Orders (Shipvia)
USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_SupplierReput') IS NOT NULL
    DROP PROCEDURE usp_SupplierReput
GO

CREATE PROCEDURE usp_SupplierReput(@Rank_No int =null )
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON

	Declare @sql varchar(2000)
    set @sql='
		Select SupplierID, SupplierName, Country, TotalProductsSold,
		RANK() OVER (Order by TotalProductsSold Desc) RankInPopularity
		from 
		(
			Select t.SupplierID, CompanyName as SupplierName, Country, TotalProductsSold 
			From( 
				   
				Select ' +
				case when @Rank_No is not null
				then 'top '+ convert(varchar,@Rank_No )
				else 'top 100' end +'
				SupplierID,  Sum(od.quantity) as TotalProductsSold
				from Products as p inner join [OrderDetails] as od 
				On p.ProductID=od.ProductID 
				group by SupplierID
				order by  2 desc

				) as t inner join Suppliers as s
				On t.SupplierID=s.SupplierID
		) as w'
		
	print @sql

	exec(@sql)

	--(29 rows affected)

    SET NOCOUNT OFF
END TRY
BEGIN CATCH
	PRINT(ERROR_MESSAGE())
END CATCH
END
GO
--************************************************************************************************
--to run the SP
exec usp_SupplierReput --total products sold for all Suppliers
exec usp_SupplierReput 11 --top 10 Suppliers based on total products sold



/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.21 Improve 2.9 with Percentile
*/


USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_SupplierReput_Percentile') IS NOT NULL
    DROP PROCEDURE usp_SupplierReput_Percentile
GO

CREATE PROCEDURE usp_SupplierReput_Percentile(@Percentile tinyint =null )
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON
    if OBJECT_ID('Supplier') is not null drop table Supplier


	Declare @sql varchar(2000)
    set @sql='
		Select SupplierID, SupplierName, Country, TotalProductsSold,
		RANK() OVER (Order by TotalProductsSold Desc) RankInPopularity
		into Supplier
		from 
		(
			Select t.SupplierID, CompanyName as SupplierName, Country, TotalProductsSold 
			From 
				   (
			Select SupplierID,  SUM(od.QUANTITY) as TotalProductsSold
			from Products as p inner join [OrderDetails] as od 
			On p.ProductID=od.ProductID 
            group by SupplierID
			
		    ) as t inner join Suppliers as s
		    On t.SupplierID=s.SupplierID
		) as w'
		
	print @sql

	exec(@sql)


	declare @TotalRows as int
	declare @PerRow as decimal(36,2)
	set @TotalRows =( Select Count(*) from Supplier)
	set @PerRow =(@TotalRows+1)*(isnull(@Percentile,0)) /100 

	declare @decimalPart as decimal(36,2)
	set @decimalPart= @PerRow-floor(@PerRow)


	declare @mediaintPart as int
	declare @intPart as int
	Set @mediaintPart=floor(@PerRow)
	if @mediaintPart =0
		set @intPart=1
	else set @intPart=floor(@PerRow)	
	

	declare @Pvalue as decimal(36,2)
	declare @PValue1 as decimal(36,2)
	if @Percentile >0 
		set @Pvalue= (select TotalProductsSold from (select * from Supplier 
														Order by TotalProductsSold 
														OFFSET (@intPart-1) ROWS
	 													FETCH NEXT 1 ROW ONLY)as t)
	--else set @Pvalue= (select TotalProductsSold from (select * from ##Supplier_p 
														--Order by TotalProductsSold
														--OFFSET (@intPart) ROWS
	 													--FETCH NEXT 1 ROW ONLY)as t)

	Set @PValue1=(Select TotalProductsSold from (Select * from Supplier 
													Order by TotalProductsSold
													offset (@intPart) rows
													fetch next 1 row only ) as t1)

	declare @Value as decimal(36,2)													
	if @decimalPart=0 set @Value=@Pvalue
	else set @Value=@Pvalue+@decimalPart*(@PValue1-@Pvalue)

	if @mediaintPart=0 
	set @value=0


	--select @TotalRows as TotalRows, @PerRow as PerRow,@intPart as intPart, @decimalPart as DecimailPart, @Pvalue as Pvalue, @PValue1 AS PValue1, @Value as Value

	declare @string as varchar(200)
	if @Percentile >0 
		set @string = + convert(varchar, @percentile)+ 'th Percentile Value is ' +convert(varchar,@Value)
	
	else set @string='No percentile is set'
	print @string

	Select SupplierID, SupplierName,Country,TotalProductsSold, RankInPopularity
	from Supplier
	where TotalProductsSold >=@Value
	Order by RankInPopularity


	Drop table Supplier

  SET NOCOUNT OFF
END TRY
BEGIN CATCH
	if OBJECT_ID('Supplier') is not null drop table Supplier
	PRINT(ERROR_MESSAGE())
END CATCH
END
GO
--************************************************************************************************
--to run the SP
exec usp_SupplierReput_Percentile --total products sold for all suppliers
exec usp_SupplierReput_Percentile 90 --suppliers whose products sold equals or above the 90th percentil value

--************************************************************************************************
USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_CustomerReput') IS NOT NULL
    DROP PROCEDURE usp_CustomerReput
GO

CREATE PROCEDURE usp_CustomerReput(@Rank_No int =null )
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON

	Declare @sql varchar(2000)
    set @sql='

Select CompanyName, Country, format (TotalPayment,''C0'')  as TotalPayment,
		SpendingPreference,Percentage, Rank() Over (Order by TotalPayment desc) as Rank
from(

Select CompanyName,Country,TotalPayment,
		SpendingPreference, format(Ratio,''P3'') as Percentage
from(

	Select CustomerID,TotalPayment,ProductName as SpendingPreference,SubTotal/TotalPayment as Ratio
	from (

		Select * 
		from(
		
			Select CustomerID,TotalPayment,ProductID,
			sum(isnull(UnitPrice*Quantity*(1-Discount),0)) as subTotal
			from( 

				Select t.CustomerID,TotalPayment, OrderID
				from ( 

					Select ' + case when @Rank_No is not null
									then ' top '+ convert(varchar,@Rank_No )
									else ' top 100 ' end +' 					
					CustomerID,  sum(isnull(UnitPrice*Quantity*(1-Discount),0)) as TotalPayment
					from Orders as o inner join [OrderDetails] as od 
					On o.OrderID=od.OrderID 
					group by CustomerID
					order by  2 desc

					) as t inner join Orders as r
					On t.CustomerID=r.CustomerID

			) as tt inner join OrderDetails as d
			on tt.OrderID=d.OrderID
			Group by CustomerID, TotalPayment,ProductID
	
		) as f1 WHERE subTotal=(select Max(subTotal) from (
		Select CustomerID,TotalPayment,ProductID,
			sum(isnull(UnitPrice*Quantity*(1-Discount),0)) as subTotal
			from( 

				Select t.CustomerID,TotalPayment, OrderID
				from ( 

					Select ' + case when @Rank_No is not null
									then ' top '+ convert(varchar,@Rank_No )
									else ' top 100 ' end +' 				
					 CustomerID,  sum(isnull(UnitPrice*Quantity*(1-Discount),0)) as TotalPayment
					from Orders as o inner join [OrderDetails] as od 
					On o.OrderID=od.OrderID 
					group by CustomerID
					order by  2 desc
					 
					) as t inner join Orders as r
					On t.CustomerID=r.CustomerID

			) as tt inner join OrderDetails as d
			on tt.OrderID=d.OrderID
			Group by CustomerID, TotalPayment,ProductID
													) as f2 where f1.customerid=f2.customerID)
	) as f inner join Products as p
	on f.ProductID=p.ProductID

) as g inner join Customers as c
on g.CustomerID=c.CustomerID

) as h'
	print @sql

	exec(@sql)

	--(29 rows affected)

    SET NOCOUNT OFF
END TRY
BEGIN CATCH
	PRINT(ERROR_MESSAGE())
END CATCH
END
GO
--************************************************************************************************
--to run the SP
exec usp_CustomerReput 20
exec usp_CustomerReput 0
exec usp_CustomerReput 5

--************************************************************************************************
USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_CustomerReput2') IS NOT NULL
    DROP PROCEDURE usp_CustomerReput2
GO
IF OBJECT_ID('Media') IS NOT NULL
    DROP Table Media
GO
CREATE PROCEDURE usp_CustomerReput2(@Rank_No int =null )
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON

	Declare @sql varchar(2000)
    set @sql='
		Select CustomerID,TotalPayment,ProductID,
		sum(isnull(UnitPrice*Quantity*(1-Discount),0)) as subTotal
		into Media
		from( 

			Select t.CustomerID,TotalPayment, OrderID
			from ( 

				Select ' + case when @Rank_No is not null
								then ' top '+ convert(varchar,@Rank_No )
								else ' top 100 ' end +' 					
				CustomerID,  sum(isnull(UnitPrice*Quantity*(1-Discount),0)) as TotalPayment
				from Orders as o inner join [OrderDetails] as od 
				On o.OrderID=od.OrderID 
				group by CustomerID
				order by  2 desc

				) as t inner join Orders as r
				On t.CustomerID=r.CustomerID

		) as tt inner join OrderDetails as d
		on tt.OrderID=d.OrderID
		Group by CustomerID, TotalPayment,ProductID



Select CompanyName, Country, format (TotalPayment,''C0'')  as TotalPayment,
		SpendingPreference,Percentage, Rank() Over (Order by TotalPayment desc) as Rank
from(

Select CompanyName,Country,TotalPayment,
		SpendingPreference, format(Ratio,''P3'') as Percentage
from(

		Select CustomerID,TotalPayment,ProductName as SpendingPreference,SubTotal/TotalPayment as Ratio
		from (

			Select * 
			from Media 
			as f1 WHERE subTotal=(select Max(subTotal) from Media
			as f2 where f1.customerid=f2.customerID)

		) as f inner join Products as p
		on f.ProductID=p.ProductID

) as g inner join Customers as c
on g.CustomerID=c.CustomerID

) as h'
	print @sql

	exec(@sql)

	--(29 rows affected)

    SET NOCOUNT OFF
	DROP Table Media
END TRY
BEGIN CATCH
	IF OBJECT_ID('Media') IS NOT NULL
    DROP Table Media
	PRINT(ERROR_MESSAGE())
END CATCH
END
GO
--************************************************************************************************
--to run the SP
exec usp_CustomerReput2 5
--with the help of media table f1, the time decreased from 12 seconds to 7 seconds