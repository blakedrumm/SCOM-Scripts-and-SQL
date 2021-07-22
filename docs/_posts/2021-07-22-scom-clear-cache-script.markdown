---
layout: post
title:  "SCOM Clear Cache Script"
date:   2021-07-22 01:09:42 -0500
categories: powershell
title: System Center Operations Manager - Clear Cache Powershell Script
description: >- # this means to ignore newlines
  Clear your Agent, Management Server, or Gateway SCOM Cache with an easy to use Powershell Script!
  The script also utilizes Invoke-Command, be sure to enable PSRemoting to allow you to utilize this script across servers if needed.
---
  The Clear SCOM Cache Script, which is located here:
  https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Clear-SCOMCache.ps1
  
  Allows you to stop the SCOM Services and clears the SCOM cache. The script will also Flush DNS Cache, Purges Kerberos Tickets, Resetting NetBIOS over TCPIP Statistics, and Resetting Winsock catalog.
<!--
Having trouble with Pages? Check out our [documentation](https://docs.github.com/categories/github-pages-basics/) or [contact support](https://support.github.com/contact) and we’ll help you sort it out.
-->
