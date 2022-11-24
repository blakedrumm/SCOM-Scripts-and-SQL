> Blog Post: [https://blakedrumm.com/blog/scom-db-move-tool/](https://blakedrumm.com/blog/scom-db-move-tool)

**Latest Version:** `1.0.0.1`

![SCOM Reconfigure DB Move Tool](https://user-images.githubusercontent.com/63755224/203679185-d8fe5366-9ef7-4b22-ba9a-fc4560c9b9cf.png)

## :book: Introduction

This tool allows you to reconfigure System Center Operations Manager's Databases in the configuration file, registry, and SQL Database Tables. This tool utilizes Powershell to provide a GUI for being able to easily navigate and verify the settings.

## :arrow_down_small: Latest Version
[![Latest Version](https://img.shields.io/github/v/release/blakedrumm/SCOM-Reconfigure-DB-Move-Tool)](https://github.com/blakedrumm/SCOM-Reconfigure-DB-Move-Tool/releases/latest) \
[![Download Count Latest](https://img.shields.io/github/downloads/blakedrumm/SCOM-Reconfigure-DB-Move-Tool/latest/SCOM-Reconfigure-DB-Move-Tool-EXE.zip?style=for-the-badge&color=brightgreen)](https://aka.ms/SCOM-DB-Move-Tool)

## :page_with_curl: How to Use

<a href="https://github.com/blakedrumm/SCOM-Reconfigure-DB-Move-Tool/releases/latest/download/SCOM-Reconfigure-DB-Move-Tool-EXE.zip" target="_"><button class="btn btn-primary navbar-btn">Get Started</button></a>

[https://aka.ms/SCOM-DB-Move-Tool](https://aka.ms/SCOM-DB-Move-Tool)

You have multiple ways to download the SCOM Reconfigure DB Move GUI Tool:
1. Download and install the MSI: [MSI Download](https://github.com/blakedrumm/SCOM-Reconfigure-DB-Move-Tool/releases/latest/download/SCOM-Reconfigure-DB-Move-Tool-MSI.zip)
2. Download and run the EXE: [EXE Downloads](https://github.com/blakedrumm/SCOM-Reconfigure-DB-Move-Tool/releases/latest/download/SCOM-Reconfigure-DB-Move-Tool-EXE.zip)
3. Download or Copy the Powershell Script to Powershell ISE: [Powershell Script](https://github.com/blakedrumm/SCOM-Reconfigure-DB-Move-Tool/releases/latest/download/SCOM-Reconfigure-DB-Move-Tool.ps1)

The script by default will attempt to gather the current database connection from the local registry. If it is unable to locate the registry keys the Database Connection box will be empty. If it is empty you will need to manually type the values in here. The Values to Set section is required for the script to run and you will need to manually populate these fields. The Management Servers section is also required for you to be able to set which Management Servers to update the Database information on.

This script will log actions to the Application Event Log. Look for the Event Source: `SCOMDBMoveTool`

## More Information

You will get prompted each time you run the script to accept the license agreement, unless you select do not ask me again, when you select this it will save a file to your ProgramData Directory: `C:\ProgramData\SCOM-DBMoveTool-AgreedToLicense.log`

If you have any questions or concerns, please leave a comment and I will do my best to assist!

Attribution for the icon:
<a href="https://www.flaticon.com/free-icons/database" title="database icons">Database icons created by manshagraphics - Flaticon</a>
