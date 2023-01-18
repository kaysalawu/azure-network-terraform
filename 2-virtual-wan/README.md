
# Virtual WAN <!-- omit from toc -->

Table of Contents
<!-- TOC -->
- [1. Virtual WAN - Single Hub](#1-virtual-wan---single-hub)
- [2. Virtual WAN - Dual Hub](#2-virtual-wan---dual-hub)
- [3. Virtual WAN - Single Hub (VPN)](#3-virtual-wan---single-hub-vpn)
- [4. Virtual WAN - Dual Hub (Mixed)](#4-virtual-wan---dual-hub-mixed)
<!-- /TOC -->

The terraform codes in this collection cover different hub and spoke network patterns using standard VNET solutions.

## 1. Virtual WAN - Single Hub
[Terraform Code](../2-virtual-wan/1-virtual-wan-single-hub/)

This code deploys a virtual WAN architecture playground to observe dynamic routing patterns. 

## 2. Virtual WAN - Dual Hub
[Terraform Code](../2-virtual-wan/2-virtual-wan-dual-hub/)

This code deploys a multi-hub (multi-region) virtual WAN architecture playground to observe dynamic routing patterns.

## 3. Virtual WAN - Single Hub (VPN)
[Terraform Code](../2-virtual-wan/3-virtual-wan-single-hub-vpn/)

This code deploys a virtual WAN architecture playground to observe dynamic routing patterns. It shows how to integrate a standard VNET hub to virtual WAN via an IPsec VPN connection.

## 4. Virtual WAN - Dual Hub (Mixed)
[Terraform Code](../2-virtual-wan/4-virtual-wan-dual-hub-mixed/)

This code deploys a multi-hub (multi-region) virtual WAN architecture playground to observe dynamic routing patterns. It shows two ways to integrate a standard VNET hub to virtual WAN - via a connection, and via IPsec VPN.
