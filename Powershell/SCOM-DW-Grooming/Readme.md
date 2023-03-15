> :notebook: **Blog Post:** [https://blakedrumm.com/blog/scom-dw-grooming-tool/](https://blakedrumm.com/blog/scom-dw-grooming-tool/) \
> :arrow_down_small: **Quick Download:** [https://aka.ms/SCOM-DW-Tool](https://aka.ms/SCOM-DW-Tool)

[![Visits Badge](https://badges.strrl.dev/visits/blakedrumm/SCOM-DW-Grooming-Tool)](https://badges.strrl.dev) \
[![Latest Version](https://img.shields.io/github/v/release/blakedrumm/SCOM-DW-Grooming-Tool)](https://github.com/blakedrumm/SCOM-DW-Grooming-Tool/releases/latest) \
[![Download Count Releases](https://img.shields.io/github/downloads/blakedrumm/SCOM-DW-Grooming-Tool/total.svg?style=for-the-badge&color=brightgreen)](https://github.com/blakedrumm/SCOM-DW-Grooming-Tool/releases) \
[![Download Count Latest](https://img.shields.io/github/downloads/blakedrumm/SCOM-DW-Grooming-Tool/latest/SCOM-DW-GroomingGUI-EXE-64bit.zip?style=for-the-badge&color=brightgreen)](https://aka.ms/SCOM-DW-Tool)

[![SCOM DW Grooming Tool](https://user-images.githubusercontent.com/63755224/208586913-e8c3c4e3-3c25-46ce-8368-7ebb768d4445.png)](https://github.com/blakedrumm/SCOM-DW-Grooming-Tool/releases/latest)


## System Center Operations Manager Data Warehouse Grooming Tool

Welcome to the official repository for the System Center Operations Manager Data Warehouse Grooming Tool. This tool is compatible with all versions of Operations Manager and is designed to help you manage and maintain your data warehouse.

### Features
- Modify retention days for your data warehouse
- View grooming history
- Manually run grooming
- Export current configuration for backup purposes
- Reset values to default settings for typical data sets in the data warehouse

### Requirements
- System Center Operations Manager installation
- Powershell 5

## How to Use

You have multiple ways to run the SCOM DW Grooming GUI Tool:

1. Download and install the MSI: [MSI Download](https://github.com/blakedrumm/SCOM-DW-Grooming-Tool/releases/latest/download/SCOM-DW-GroomingGUI-MSI.zip)
2. Download and run the EXE: [EXE Downloads](https://github.com/blakedrumm/SCOM-DW-Grooming-Tool/releases/latest/download/SCOM-DW-GroomingGUI-EXE-64bit.zip)
3. Download or Copy the Powershell Script: [Powershell Script](https://github.com/blakedrumm/SCOM-DW-Grooming-Tool/releases/latest/download/SCOM-DW-GroomingGUI.ps1)

You will need to provide the Data Warehouse DB Server Name or Address, and the Data Warehouse Database Name. The script may auto detect these variables from the local registry on the machine you are running the script. To get started, you will need to press the **Get Current Settings** button. This will allow the script to gather the information from the Data Warehouse database server. Once you make the changes you can save the change with **Set**.

This script will log some actions to the Application Event Log. Look for the Event Source: `SCOMDWTool`

## More Information

You will get prompted each time you run the script to accept the license agreement, unless you select do not ask me again, when you select this it will save a file to your ProgramData Directory:
```
C:\ProgramData\SCOM-DataWarehouseGUI-AgreedToLicense.log
```

<!-- ![Visits](https://counter.blakedrumm.com/count/tag.svg?url=https://github.com/blakedrumm/SCOM-DW-Grooming-Tool) -->
