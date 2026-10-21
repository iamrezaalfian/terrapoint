import subprocess
import time
import os
import re

AUTH_URL = "https://login.tailscale.com/a/l174bf1144aa639"
print(f"Opening browser for Tailscale SSH Check: {AUTH_URL}")
subprocess.Popen(["cmd.exe", "/c", "start", AUTH_URL], shell=False)

remote_commands = """
echo "=== 1. Installing Redis Server ==="
echo "Terrapoint2026!Dev" | sudo -S apt update && echo "Terrapoint2026!Dev" | sudo -S apt install -y redis-server
echo "Terrapoint2026!Dev" | sudo -S systemctl enable --now redis-server
echo "Redis Ping:" $(redis-cli ping)

echo "=== 2. Cleaning Remote PostgreSQL Database ==="
cd /home/terrapoint/terrapoint/server_vps/backend
bun -e '
const { Pool } = require("pg");
require("dotenv").config();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
async function clean() {
  await pool.query("DELETE FROM master_locations WHERE location_id LIKE \\'LOC-17%\\'");
  await pool.query("DELETE FROM tasks WHERE task_id IN (\\'TSK-MRO-001\\', \\'TSK-MRO-002\\', \\'TSK-MRO-003\\')");
  console.log("Deleted dummy Morowali tasks and locations!");
  const t = await pool.query("SELECT task_id, title FROM tasks");
  console.log("Tasks in DB now:", t.rows);
  const l = await pool.query("SELECT location_id, name FROM master_locations");
  console.log("Locations in DB now:", l.rows);
  await pool.end();
}
clean().catch(console.error);
'

echo "=== 3. Disabling Tailscale SSH check interception so OpenSSH handles port 22 directly ==="
echo "Terrapoint2026!Dev" | sudo -S tailscale set --ssh=false

echo "=== 4. Restarting TerraPoint Service ==="
echo "Terrapoint2026!Dev" | sudo -S systemctl restart terrapoint
echo "Terrapoint Status:" $(echo "Terrapoint2026!Dev" | sudo -S systemctl is-active terrapoint)
"""

print("Connecting to server via SSH...")
p = subprocess.Popen(
    ["ssh", "-o", "StrictHostKeyChecking=no", "terrapoint@100.89.207.92", "bash -s"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

stdout, stderr = p.communicate(input=remote_commands, timeout=90)
print("STDOUT:\n", stdout)
print("STDERR:\n", stderr)
