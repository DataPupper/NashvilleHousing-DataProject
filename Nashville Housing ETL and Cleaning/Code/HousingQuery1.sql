
select * from HousingData

------------------------------------------------------------STEP 1------------------------------------------------------------
--to fix the SaleDate format from datetime to date
Select SaleDate from HousingData

--creating an alias to take the coverted datatype (UPDATE operation didn't help/affect)
alter table HousingData add SaleDated date

update HousingData set SaleDated = Convert(date,SaleDate)

------------------------------------------------------------STEP 2------------------------------------------------------------
--to get rid of NULLs inn property address
select PropertyAddress from HousingData
where PropertyAddress is NULL

--in SQL display row no 61 & 62 see Same ParcelIDs have same PropertyAddresses 
select * from HousingData
order by ParcelID

--inner join to test the theory and a probable population for the nulls
select a.ParcelID, a.PropertyAddress, a.[UniqueID ], b.ParcelID, b.PropertyAddress, b.[UniqueID ]
from HousingData a
Join HousingData b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is Null

--temp populating the Nulls
select a.ParcelID, a.PropertyAddress, a.[UniqueID ], b.ParcelID, b.PropertyAddress, b.[UniqueID ], ISNULL(a.PropertyAddress,b.PropertyAddress)
from HousingData a
Join HousingData b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is Null

--Finally updating table after getting desired results
update a set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from HousingData a
Join HousingData b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is Null

------------------------------------------------------------STEP 3------------------------------------------------------------
--To set proprty address aside from its mentioned city
select PropertyAddress from HousingData

--to keep only a part of the string SUBSTRING(string (where to look), start (where to start search), length/position of change)
--to break by an exact location/point CHARINDEX(substring (what to look for), string (where to look), start (optional!))

Select SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1) as Address,-- the -1 is to get rid of the comma so break till the position of the comma and then go 1 spot behind it
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) as City
from HousingData

--finally make the above change to the table
--Address Only
alter table HousingData add SpecificPropertyAddress nvarchar(150)

update HousingData set SpecificPropertyAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1)

--City only
alter table HousingData add PropertyCity nvarchar(150)

update HousingData set PropertyCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

------------------------------------------------------------STEP 4------------------------------------------------------------
--To set owner address aside from its mentioned city/state
select OwnerAddress from HousingData

--PARSENAME('NameOfStringToParse',PartIndex) is a good option when data containing delimiters
--but the thing with PARSENAME is that it starts count in reverse so either count opp. like below 3 -> 2 -> 1 or add a REVERSE function and then parse in it
select PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),--> 3 starts at 1st worst
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
from HousingData

--finally make the above change to the table
--Address Only
alter table HousingData add SpecificOwnerAddress nvarchar(150)

update HousingData set SpecificOwnerAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

--City only
alter table HousingData add OwnerCity nvarchar(150)

update HousingData set OwnerCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

--State only
alter table HousingData add OwnerState nvarchar(150)

update HousingData set OwnerState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

------------------------------------------------------------STEP 5------------------------------------------------------------
--To bring uniformity to the SoldAsVacant column with only 'Yes' & 'No' instead of 'yes' 'no' 'y' & 'n'
select DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
from HousingData
group by SoldAsVacant
order by 2

select SoldAsVacant,
	CASE when SoldAsVacant = 'Y' then 'Yes'
		 when SoldAsVacant = 'N' then 'No'
		 else SoldAsVacant
	END
from HousingData

update HousingData
set SoldAsVacant = CASE when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant
					END

------------------------------------------------------------STEP 6------------------------------------------------------------
--To remove duplicate values
select *, 
ROW_NUMBER() over (Partition By ParcelID, SpecificPropertyAddress, PropertyCity, SaleDated, SalePrice, LegalReference Order by UniqueID) as row_num
from HousingData
order by ParcelID

--creating a CTE
WITH UniqueRowCTE as
	(
	select *, 
	ROW_NUMBER() over (Partition By ParcelID, SpecificPropertyAddress, PropertyCity, SaleDated, SalePrice, LegalReference Order by UniqueID) as row_num
	from HousingData
	)
delete from UniqueRowCTE
where row_num > 1

--to check the above and make sure there are zero duplicates
WITH UniqueRowCTE as
	(
	select *, 
	ROW_NUMBER() over (Partition By ParcelID, SpecificPropertyAddress, PropertyCity, SaleDated, SalePrice, LegalReference Order by UniqueID) as row_num
	from HousingData
	)
select * from UniqueRowCTE
where row_num > 1

------------------------------------------------------------STEP 7------------------------------------------------------------
select * from HousingData

--dropping columns to reduce redundancy 
alter table HousingData drop column SaleDate, PropertyAddress, OwnerAddress
