#!/bin/bash
set -e  # Exit on any error

# 1. Use AWS profile "mj"
export AWS_PROFILE=mj
echo "🔐 Using AWS profile: $AWS_PROFILE"

# 2. Get EC2 instance ID and API Gateway URL
INSTANCE_ID=$(terraform output -raw latency_tester_instance_id)
API_URL=$(terraform output -raw api_gateway_url)
echo "🖥️  EC2 Instance ID: $INSTANCE_ID"
echo "🔗 API Gateway URL: $API_URL"

# Helper function to wait for command completion
wait_for_command() {
    local cmd_id=$1
    local status
    echo "⏳ Waiting for command to complete..."
    while true; do
        status=$(aws ssm list-commands --command-id "$cmd_id" --query 'Commands[0].Status' --output text)
        if [ "$status" = "Success" ]; then
            echo "✅ Command completed successfully"
            break
        elif [ "$status" = "Failed" ] || [ "$status" = "Cancelled" ] || [ "$status" = "TimedOut" ]; then
            echo "❌ Command failed with status: $status"
            echo "📝 Error details:"
            aws ssm get-command-invocation \
                --command-id "$cmd_id" \
                --instance-id "$INSTANCE_ID" \
                --query "[StandardErrorContent,StandardOutputContent]" \
                --output text
            exit 1
        fi
        sleep 2
    done
}

# 3. Copy test_gateway.py to EC2 using base64 encoding
echo "📝 Copying test script to EC2..."
SCRIPT_CONTENT=$(cat test_gateway.py | base64)
CMD_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters commands="[\
        \"echo '$SCRIPT_CONTENT' | base64 -d > ~/test_gateway.py\"\
    ]" \
    --query 'Command.CommandId' \
    --output text)
wait_for_command "$CMD_ID"

# 4. Setup Python environment and run test
echo "🚀 Setting up environment and running test..."
CMD_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters commands="[\
        \"chmod +x ~/test_gateway.py\",\
        \"python3 -m pip uninstall -y urllib3 requests >/dev/null\",\
        \"python3 -m pip install --user --quiet 'urllib3<2.0' requests numpy\",\
        \"echo '=== Starting Latency Test ==='\",\
        \"python3 ~/test_gateway.py --url $API_URL\",\
        \"echo '=== Test Complete ===' \"\
    ]" \
    --query 'Command.CommandId' \
    --output text)
wait_for_command "$CMD_ID"

# 5. Get and show the test results
echo "📊 Test Results:"
OUTPUT=$(aws ssm get-command-invocation \
    --command-id "$CMD_ID" \
    --instance-id "$INSTANCE_ID" \
    --query "StandardOutputContent" \
    --output text)

# Extract and show only the test results
if echo "$OUTPUT" | grep -q "=== Starting Latency Test ==="; then
    echo "$OUTPUT" | sed -n '/=== Starting Latency Test ===/,/=== Test Complete ===/p' | \
        grep -v "=== Starting Latency Test ===" | \
        grep -v "=== Test Complete ==="
else
    echo "❌ Could not find test results in output:"
    echo "$OUTPUT"
    exit 1
fi

echo "✅ Latency test complete!" 