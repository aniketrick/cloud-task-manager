import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
    try {
        // 1. Parse the incoming data
        const body = JSON.parse(event.body || "{}");
        const { userId, title } = body;

        // 2. Validation Check
        if (!userId || !title) {
            return {
                statusCode: 400,
                headers: { "Access-Control-Allow-Origin": "*" },
                body: JSON.stringify({ message: "userId and title are required" }),
            };
        }

        const taskId = Date.now().toString(); 

        // 3. Prepare the Item (Must match your Terraform Schema)
        const newTask = {
            userId: userId,           // Partition Key
            taskId: taskId,           // Sort Key
            title: title,
            status: "pending",
            createdAt: new Date().toISOString()
        };

        const command = new PutCommand({
            TableName: "Tasks-Terraform", // Must match your resource name
            Item: newTask,
        });

        // 4. Send to DynamoDB
        await docClient.send(command);

        // 5. Return success with CORS headers
        return {
            statusCode: 201,
            headers: { 
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*" // Allows React to talk to this API
            },
            body: JSON.stringify({ 
                message: "Task created successfully!", 
                task: newTask 
            })
        };

    } catch (error) {
        console.error("Error creating task:", error);
        return {
            statusCode: 500,
            headers: { "Access-Control-Allow-Origin": "*" },
            body: JSON.stringify({ message: "Internal Server Error", details: error.message }),
        };
    }
};