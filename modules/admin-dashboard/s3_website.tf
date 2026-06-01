#------------------------------------------------------------------------------
# S3 Bucket for Static Website
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = "${local.name_prefix}-admin-website-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-admin-website"
  })
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

#------------------------------------------------------------------------------
# CloudFront Origin Access Control
#------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${local.name_prefix}-website-oac"
  description                       = "OAC for admin website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#------------------------------------------------------------------------------
# S3 Bucket Policy for CloudFront
#------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.admin.arn
          }
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Upload index.html
#------------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content_type = "text/html"

  content = <<-EOF
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>BigBlueButton Admin</title>
        <script src="https://cdn.jsdelivr.net/npm/amazon-cognito-identity-js@6/dist/amazon-cognito-identity.min.js"></script>
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }
            .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
            header { background: #1a73e8; color: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; }
            h1 { font-size: 24px; }
            .card { background: white; border-radius: 8px; padding: 20px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .card h2 { margin-bottom: 15px; color: #333; }
            .btn { padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; margin-right: 10px; }
            .btn-primary { background: #1a73e8; color: white; }
            .btn-success { background: #34a853; color: white; }
            .btn-danger { background: #ea4335; color: white; }
            .btn:hover { opacity: 0.9; }
            .status { padding: 8px 16px; border-radius: 20px; display: inline-block; font-weight: 500; }
            .status-running { background: #e6f4ea; color: #137333; }
            .status-stopped { background: #fce8e6; color: #c5221f; }
            .status-pending { background: #fef7e0; color: #b06000; }
            #login-form { max-width: 400px; margin: 100px auto; }
            #login-form input { width: 100%; padding: 12px; margin-bottom: 15px; border: 1px solid #ddd; border-radius: 4px; }
            .file-list { max-height: 400px; overflow-y: auto; }
            .file-item { padding: 10px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center; }
            .file-item:hover { background: #f8f9fa; }
            .hidden { display: none; }
            #message { padding: 10px; margin: 10px 0; border-radius: 4px; }
            .error { background: #fce8e6; color: #c5221f; }
            .success { background: #e6f4ea; color: #137333; }
        </style>
    </head>
    <body>
        <div id="login-section">
            <div class="container">
                <div class="card" id="login-form">
                    <h2>BigBlueButton Admin Login</h2>
                    <div id="message" class="hidden"></div>
                    <input type="email" id="email" placeholder="Email" required>
                    <input type="password" id="password" placeholder="Password" required>
                    <button class="btn btn-primary" onclick="login()">Sign In</button>
                </div>
            </div>
        </div>

        <div id="dashboard-section" class="hidden">
            <div class="container">
                <header>
                    <h1>BigBlueButton Administration</h1>
                    <button class="btn" style="background: rgba(255,255,255,0.2); color: white; float: right; margin-top: -30px;" onclick="logout()">Logout</button>
                </header>

                <div class="card">
                    <h2>VM Control</h2>
                    <p style="margin-bottom: 15px;">Status: <span id="vm-status" class="status status-pending">Checking...</span></p>
                    <button class="btn btn-success" onclick="controlVM('start')">Start VM</button>
                    <button class="btn btn-danger" onclick="controlVM('stop')">Stop VM</button>
                    <button class="btn btn-primary" onclick="refreshStatus()">Refresh Status</button>
                </div>

                <div class="card">
                    <h2>Recordings</h2>
                    <button class="btn btn-primary" onclick="listRecordings()" style="margin-bottom: 15px;">Refresh List</button>
                    <div class="file-list" id="recordings-list">
                        <p>Click "Refresh List" to load recordings</p>
                    </div>
                </div>
            </div>
        </div>

        <script>
            const CONFIG = {
                userPoolId: '${aws_cognito_user_pool.admin.id}',
                clientId: '${aws_cognito_user_pool_client.admin.id}',
                apiEndpoint: '${aws_api_gateway_stage.admin.invoke_url}'
            };

            let idToken = null;

            function showMessage(msg, isError) {
                const el = document.getElementById('message');
                el.textContent = msg;
                el.className = isError ? 'error' : 'success';
                el.classList.remove('hidden');
            }

            async function login() {
                const email = document.getElementById('email').value;
                const password = document.getElementById('password').value;

                const authData = {
                    Username: email,
                    Password: password
                };

                const authDetails = new AmazonCognitoIdentity.AuthenticationDetails(authData);
                const poolData = {
                    UserPoolId: CONFIG.userPoolId,
                    ClientId: CONFIG.clientId
                };
                const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);
                const userData = {
                    Username: email,
                    Pool: userPool
                };
                const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);

                cognitoUser.authenticateUser(authDetails, {
                    onSuccess: (result) => {
                        idToken = result.getIdToken().getJwtToken();
                        localStorage.setItem('idToken', idToken);
                        showDashboard();
                    },
                    onFailure: (err) => {
                        showMessage(err.message || 'Login failed', true);
                    },
                    newPasswordRequired: (userAttributes) => {
                        showMessage('Please change your password on first login', true);
                    }
                });
            }

            function logout() {
                localStorage.removeItem('idToken');
                idToken = null;
                document.getElementById('login-section').classList.remove('hidden');
                document.getElementById('dashboard-section').classList.add('hidden');
            }

            function showDashboard() {
                document.getElementById('login-section').classList.add('hidden');
                document.getElementById('dashboard-section').classList.remove('hidden');
                refreshStatus();
            }

            async function apiCall(endpoint, method, body) {
                const response = await fetch(CONFIG.apiEndpoint + endpoint, {
                    method: method,
                    headers: {
                        'Authorization': idToken,
                        'Content-Type': 'application/json'
                    },
                    body: body ? JSON.stringify(body) : undefined
                });
                return response.json();
            }

            async function refreshStatus() {
                try {
                    const result = await apiCall('/ec2', 'GET');
                    const data = JSON.parse(result.body);
                    const statusEl = document.getElementById('vm-status');
                    statusEl.textContent = data.status;
                    statusEl.className = 'status status-' + (data.status === 'running' ? 'running' : data.status === 'stopped' ? 'stopped' : 'pending');
                } catch (e) {
                    console.error('Failed to get status:', e);
                }
            }

            async function controlVM(action) {
                try {
                    await apiCall('/ec2', 'POST', { action: action });
                    setTimeout(refreshStatus, 2000);
                } catch (e) {
                    console.error('Failed to control VM:', e);
                }
            }

            async function listRecordings() {
                try {
                    const result = await apiCall('/recordings', 'GET');
                    const data = JSON.parse(result.body);
                    const listEl = document.getElementById('recordings-list');

                    if (data.files && data.files.length > 0) {
                        listEl.innerHTML = data.files.map(f =>
                            '<div class="file-item">' +
                            '<span>' + f.key + ' (' + formatBytes(f.size) + ')</span>' +
                            '<button class="btn btn-primary" onclick="downloadFile(\'' + f.key + '\')">Download</button>' +
                            '</div>'
                        ).join('');
                    } else {
                        listEl.innerHTML = '<p>No recordings found</p>';
                    }
                } catch (e) {
                    console.error('Failed to list recordings:', e);
                }
            }

            async function downloadFile(key) {
                try {
                    const result = await apiCall('/recordings', 'POST', { action: 'download', key: key });
                    const data = JSON.parse(result.body);
                    window.open(data.downloadUrl, '_blank');
                } catch (e) {
                    console.error('Failed to get download URL:', e);
                }
            }

            function formatBytes(bytes) {
                if (bytes === 0) return '0 B';
                const k = 1024;
                const sizes = ['B', 'KB', 'MB', 'GB'];
                const i = Math.floor(Math.log(bytes) / Math.log(k));
                return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
            }

            // Check for existing session
            window.onload = () => {
                const savedToken = localStorage.getItem('idToken');
                if (savedToken) {
                    idToken = savedToken;
                    showDashboard();
                }
            };
        </script>
    </body>
    </html>
  EOF

  tags = local.common_tags
}
