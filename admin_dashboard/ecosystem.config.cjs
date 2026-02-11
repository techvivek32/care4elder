module.exports = {
  apps: [
    {
      name: "care4elder-admin",
      cwd: "/var/www/care4elder/admin_dashboard",
      script: "node_modules/next/dist/bin/next",
      args: "start -p 3001",
      env: {
        NODE_ENV: "production"
      }
    }
  ]
}