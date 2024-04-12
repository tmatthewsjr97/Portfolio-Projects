--Data Cleaning Project

Select SaleDate
From NashvilleHousingProject.dbo.NashvilleHousing

--Populating Property Address Data

Select PropertyAddress
From NashvilleHousingProject.dbo.NashvilleHousing
Where PropertyAddress is null
--Investigating the Data
Select *
From NashvilleHousingProject.dbo.NashvilleHousing
--Where PropertyAddress is null
Order By ParcelID
--
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousingProject.dbo.NashvilleHousing a
JOIN NashvilleHousingProject.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null
--Begin a transaction in order to rollback and not permanently modify the table
BEGIN TRANSACTION

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousingProject.dbo.NashvilleHousing a
JOIN NashvilleHousingProject.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

COMMIT


--Now lets break down the Address into individual columns

Select PropertyAddress
From NashvilleHousingProject.dbo.NashvilleHousing
--

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))as Address

FROM NashvilleHousingProject.dbo.NashvilleHousing

--

ALTER TABLE NashvilleHousingProject.dbo.NashvilleHousing
Add PropertySplitAddress nvarchar(255);

Update NashvilleHousingProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousingProject.dbo.NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update NashvilleHousingProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


Select *
From NashvilleHousingProject.dbo.NashvilleHousing

--Data is now more accessible that address and city are split

--Alternative way to separate address, town, and state into individual columns

Select OwnerAddress
From NashvilleHousingProject.dbo.NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousingProject.dbo.NashvilleHousing


ALTER TABLE NashvilleHousingProject.dbo.NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

Update NashvilleHousingProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousingProject.dbo.NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update NashvilleHousingProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousingProject.dbo.NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update NashvilleHousingProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Now we need to standardize the SoldAsVacant Column by changing Y and N to Yes and No

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousingProject.dbo.NashvilleHousing
Group By SoldAsVacant
Order By 2

Select SoldAsVacant, 
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	Else SoldAsVacant
	END
From NashvilleHousingProject.dbo.NashvilleHousing

Update NashvilleHousingProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	Else SoldAsVacant
	END
From NashvilleHousingProject.dbo.NashvilleHousing

--Now we need to remove duplicates.

WITH RowNumCTE AS(
 Select * , 
 ROW_NUMBER()OVER (
 PARTITION BY ParcelID, 
			PropertyAddress,
			SalePrice, 
			SaleDate,
			LegalReference
			ORDER BY UniqueID) row_num

 From NashvilleHousingProject.dbo.NashvilleHousing)
 
 Select*
 From RowNumCTE
 Where row_num > 1
 Order by PropertyAddress
 --104 duplicate Rows Found, now to delete them. 
 Delete
 From RowNumCTE
 Where row_num > 1

 ------------------------------------------------------------------------------
 --Now time to remove all the unused columns 

 Select *
 From NashvilleHousingProject.dbo.NashvilleHousing

 Alter Table NashvilleHousingProject.dbo.NashvilleHousing
 Drop Column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate



