#!/usr/bin/env python3
"""
Simple webhook receiver for Alertmanager notifications
Handles incoming alerts and can be extended to send to various notification channels
"""

import json
import logging
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class AlertWebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle incoming webhook POST requests"""
        try:
            # Parse the URL path to determine alert type
            path = urlparse(self.path).path
            alert_type = path.split('/')[-1] if '/' in path else 'default'
            
            # Read the request body
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Parse JSON data
            alert_data = json.loads(post_data.decode('utf-8'))
            
            # Process the alert
            self.process_alert(alert_type, alert_data)
            
            # Send response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')
            
        except Exception as e:
            logger.error(f"Error processing webhook: {e}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b'{"status": "error"}')
    
    def process_alert(self, alert_type: str, alert_data: dict):
        """Process incoming alert based on type"""
        logger.info(f"Received {alert_type} alert")
        
        # Extract alert information
        status = alert_data.get('status', 'unknown')
        alerts = alert_data.get('alerts', [])
        
        for alert in alerts:
            labels = alert.get('labels', {})
            annotations = alert.get('annotations', {})
            
            alert_name = labels.get('alertname', 'Unknown')
            severity = labels.get('severity', 'unknown')
            service = labels.get('service', 'unknown')
            instance = labels.get('instance', 'unknown')
            
            summary = annotations.get('summary', 'No summary available')
            description = annotations.get('description', 'No description available')
            
            # Log the alert
            logger.info(f"Alert: {alert_name}")
            logger.info(f"Status: {status}")
            logger.info(f"Severity: {severity}")
            logger.info(f"Service: {service}")
            logger.info(f"Instance: {instance}")
            logger.info(f"Summary: {summary}")
            logger.info(f"Description: {description}")
            logger.info("-" * 50)
            
            # Route alert based on type
            if alert_type == 'critical':
                self.handle_critical_alert(alert)
            elif alert_type == 'database':
                self.handle_database_alert(alert)
            elif alert_type == 'security':
                self.handle_security_alert(alert)
            elif alert_type == 'development':
                self.handle_development_alert(alert)
            elif alert_type == 'operations':
                self.handle_operations_alert(alert)
            else:
                self.handle_default_alert(alert)
    
    def handle_critical_alert(self, alert):
        """Handle critical alerts with immediate attention"""
        logger.warning("🚨 CRITICAL ALERT - Immediate attention required!")
        # In production, this could send SMS, call PagerDuty, etc.
    
    def handle_database_alert(self, alert):
        """Handle database-specific alerts"""
        logger.info("🗄️ Database alert - Notifying database team")
        # In production, this could send to database team Slack channel
    
    def handle_security_alert(self, alert):
        """Handle security alerts"""
        logger.warning("🔒 Security alert - Notifying security team")
        # In production, this could trigger immediate security response
    
    def handle_development_alert(self, alert):
        """Handle application/development alerts"""
        logger.info("💻 Development alert - Notifying dev team")
        # In production, this could send to dev team notifications
    
    def handle_operations_alert(self, alert):
        """Handle operations/infrastructure alerts"""
        logger.info("⚙️ Operations alert - Notifying ops team")
        # In production, this could send to ops team channels
    
    def handle_default_alert(self, alert):
        """Handle default/unknown alert types"""
        logger.info("📢 General alert - Default handling")
    
    def do_GET(self):
        """Handle health check requests"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status": "healthy", "service": "webhook-receiver"}')
        else:
            self.send_response(404)
            self.end_headers()

def run_webhook_server():
    """Run the webhook server"""
    server_address = ('', 5001)
    httpd = HTTPServer(server_address, AlertWebhookHandler)
    
    logger.info("Starting webhook receiver on port 5001...")
    logger.info("Available endpoints:")
    logger.info("  POST /webhook/critical - Critical alerts")
    logger.info("  POST /webhook/database - Database alerts")
    logger.info("  POST /webhook/security - Security alerts") 
    logger.info("  POST /webhook/development - Development alerts")
    logger.info("  POST /webhook/operations - Operations alerts")
    logger.info("  GET /health - Health check")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down webhook receiver...")
        httpd.server_close()

if __name__ == '__main__':
    run_webhook_server()
