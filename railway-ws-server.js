import { WebSocketServer } from "ws";

const PORT = process.env.PORT || 3000;
const wss = new WebSocketServer({ port: PORT });

console.log("WebSocket server listening on", PORT);

const devices = new Map();
const clients = new Set();

wss.on("connection", (socket) => {
  let deviceId = null;
  let isDevice = false;

  clients.add(socket);

  socket.on("message", (msg) => {
    // If it's JSON, try parsing
    let data;
    try {
      data = JSON.parse(msg);
    } catch (e) {
      return;
    }

    // Device registration
    if (data.type === "register") {
      deviceId = data.deviceId;
      devices.set(deviceId, socket);
      isDevice = true;
      console.log("Device connected:", deviceId);
      return;
    }

    // UI sending plain command text to specific device
    if (data.type === "sendToDevice") {
      const t = devices.get(data.deviceId);
      if (t) {
        t.send(data.cmd);  // Send raw string command!
      }
      return;
    }

    // Device sends back status or echo
    if (data.type === "status" && isDevice) {
      for (const c of clients) {
        if (c !== socket) {
          c.send(JSON.stringify({
            deviceId,
            message: data.message
          }));
        }
      }
      return;
    }
  });

  socket.on("close", () => {
    clients.delete(socket);
    if (isDevice && deviceId) {
      devices.delete(deviceId);
      console.log("Device disconnected:", deviceId);
    }
  });
});

/**
 *  Module structure for railway-ws-server.js
 * 
 * {
  "type": "module",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "ws": "^8.17.0"
  }
}
 * 
 * 
 * **/