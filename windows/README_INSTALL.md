# Neerad Store - Windows Deployment Guide

This guide explains how to create the final installer and handle the MySQL database for your users.

## 1. Create the Application Bundle
You have already built the Windows application. The files are located in:
`build\windows\x64\runner\Release\`

## 2. Generate the Installer (.exe)
1. Install [Inno Setup](https://jrsoftware.org/isdl.php) (if not already installed).
2. Open `windows/installer_setup.iss` in Inno Setup.
3. Pulse **F9** or click **Build > Compile**.
4. The setup file will be generated in `build/installer/NeeradStoreSetup.exe`.

## 3. Handling the Database (MySQL)
To make the installation seamless for users, you have two main options:

### Option A: Manual Installation (Easiest for you)
Inform the user that they need to install MySQL Server.
- Provide the [MySQL Community Link](https://dev.mysql.com/downloads/installer/).
- The app expects:
  - **Host**: 127.0.0.1
  - **User**: root
  - **Password**: 1234
  - **Database**: neeradstore (The app creates this automatically if MySQL is running).

### Option B: Bundled Portable MariaDB (Best for users)
You can include a portable version of MariaDB inside your app folder.
1. Download [MariaDB Portable](https://mariadb.org/download/).
2. Place the MariaDB folder inside `windows/dist/database/`.
3. Update the Inno Setup script to include this folder.
4. Add a `[Run]` command to start the DB service on app launch.

## 4. Final Cleanup
The codebase has been optimized:
- Switched to `mysql_client` for better compatibility.
- Cleaned up redundant imports and lints.
- Standardized UI colors for Dark Mode.
- Implemented persistent settings in the database.
