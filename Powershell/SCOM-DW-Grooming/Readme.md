> Blog Post: [https://blakedrumm.com/blog/scom-dw-grooming-tool/](https://blakedrumm.com/blog/scom-dw-grooming-tool/)

**Latest Version:** `1.0.5.4`

![SCOM DW Grooming Tool](https://user-images.githubusercontent.com/63755224/165334550-e71685f9-8033-4e00-96d7-28aff34a5720.png)

## Introduction

This tool can be used to modify the System Center Operations Manager Data Warehouse Grooming retention days, allows you to see grooming history, you can manually run grooming, and you may also export the current configuration so you can keep a backup of your settings. You have the option of resetting the values to Defaults for the typical data sets in the Data Warehouse.

## How to Use

You have multiple ways to run the SCOM DW Grooming GUI Tool:

1. Download and install the MSI: [MSI Download](https://github.com/blakedrumm/SCOM-Scripts-and-SQL/raw/master/Powershell/SCOM-DW-Grooming/Installer%20(MSI)/SCOM-DW-GroomingGUI.msi)
2. Download and run the EXE: [EXE Downloads](https://github.com/blakedrumm/SCOM-Scripts-and-SQL/tree/master/Powershell/SCOM-DW-Grooming/Executable%20(EXE))
3. Download or Copy the Powershell Script: [Powershell Script](https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/SCOM-DW-Grooming/Source%20(PS1)/SCOM-DW-GroomingGUI.ps1)

You will need to provide the Data Warehouse DB Server Name or Address, and the Data Warehouse Database Name. The script may auto detect these variables from the local registry on the machine you are running the script. To get started, you will need to press the **Get Current Settings** button. This will allow the script to gather the information from the Data Warehouse database server. Once you make the changes you can save the change with **Set**.

This script will log some actions to the Application Event Log. Look for the Event Source: `SCOMDWTool`

## More Information

You will get prompted each time you run the script to accept the license agreement, unless you select do not ask me again, when you select this it will save a file to your ProgramData Directory: `C:\ProgramData\SCOM-DataWarehouseGUI-AgreedToLicense.log`

![Visits](https://counter.blakedrumm.com/count/tag.svg?url=https://github.com/blakedrumm/SCOM-Scripts-and-SQL/tree/master/Powershell/SCOM-DW-Grooming)
