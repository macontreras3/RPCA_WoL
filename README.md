# RPCA_WoL
Sample script to configure WoL for CVAD Remote PC Access

To run the script:
1) Open Powershell prompt with user that has admin rights on the CVAD site.
2) Set the Execution Policy accordingly to allow you to run the script. Alternatively, run the following command:
   powershell.exe -ExecutionPolicy Bypass
3) The script has two optional parameters:
   - -mcState
   Determines whether to create a new Machine Catalog or use an existing one.
   Values: New, Existing

   - -mcName
   Name for the new Machine Catalog to be created, or, name of the existing Machine Catalog to use with the new Wake on LAN connection.

4) If the parameters are not provided, the script will prompt you for these values at runtime.

Examples:

Without parameters:
.\RPCA_WakeOnLAN.ps1

With parameters:
.\RPCA_WakeOnLAN.ps1 -mcState new -mcName FTL_HDX_RPCA
