const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    const { title } = JSON.parse(event.body);
    const taskId = Date.now().toString(); // Simple unique ID

    const command = new PutCommand({
        TableName: "Tasks",
        Item: {
            taskId: taskId,
            title: title,
            status: "pending",
            createdAt: new Date().toISOString()
        },
    });

    await docClient.send(command);

    return {
        statusCode: 201,
        body: JSON.stringify({ message: "Task created!", taskId }),
        headers: { "Content-Type": "application/json" }
    };
};