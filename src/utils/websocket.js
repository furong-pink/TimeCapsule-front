// WebSocket 封装服务
class WebSocketService {
    constructor() {
        this.socket = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 3000; // 3秒重连一次
        this.listeners = [];
        this.userId = null;
    }

    connect(userId) {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) return;
        
        this.userId = userId;
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const host = window.location.host;
        // 注意：在开发环境下，由于有 vite 代理，我们需要确保路径能正确映射到后端
        // 或者直接连接到后端端口（如果跨域允许）
        // 假设通过 /api/ws/{userId} 访问
        const wsUrl = `${protocol}//${host}/api/ws/${userId}`;
        
        console.log(`正在连接 WebSocket: ${wsUrl}`);
        this.socket = new WebSocket(wsUrl);

        this.socket.onopen = () => {
            console.log('WebSocket 连接成功');
            this.reconnectAttempts = 0;
        };

        this.socket.onmessage = (event) => {
            console.log('收到 WebSocket 消息:', event.data);
            try {
                const data = JSON.parse(event.data);
                this.listeners.forEach(callback => callback(data));
            } catch (e) {
                console.warn('解析 WebSocket 消息失败:', e);
            }
        };

        this.socket.onclose = () => {
            console.log('WebSocket 连接关闭');
            this.attemptReconnect();
        };

        this.socket.onerror = (error) => {
            console.error('WebSocket 错误:', error);
        };
    }

    attemptReconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`尝试重连 WebSocket (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);
            setTimeout(() => {
                this.connect(this.userId);
            }, this.reconnectDelay);
        } else {
            console.error('WebSocket 重连失败，达到最大尝试次数');
        }
    }

    onMessage(callback) {
        this.listeners.push(callback);
    }

    disconnect() {
        if (this.socket) {
            this.socket.close();
            this.socket = null;
        }
    }
}

export default new WebSocketService();
