const { app, BrowserWindow } = require('electron');
const express = require('express');
const path = require('path');

let win;

function createWindow() {
  win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  win.maximize(); // Maximize a janela do aplicativo
  // Carregar o arquivo index.html do aplicativo Angular usando um servidor Express
  win.loadURL('http://localhost:3000/index.html');
  win.webContents.openDevTools();

  win.on('closed', () => {
    win = null;
  });
}

app.on('ready', () => {
  // Iniciar um servidor Express para servir os arquivos do aplicativo
  app.whenReady().then(() => {
    const server = express();

    // Rota para servir os arquivos estáticos do diretório 'dist'
    server.use(express.static(path.join(__dirname, 'dist')));

    server.listen(3000, () => {
      createWindow();
    });
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
