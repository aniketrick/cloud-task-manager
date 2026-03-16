import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  // Grab the userId from the URL parameters (e.g., /tasks?userId=123)
  const userId = event.queryStringParameters?.userId;

  if (!userId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "userId is required" }),
    };
  }

  const command = new QueryCommand({
    TableName: "Tasks-Terraform",
    KeyConditionExpression: "userId = :u",
    ExpressionAttributeValues: {
      ":u": userId,
    },
  });

  try {
    const response = await docClient.send(command);
    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify(response.Items),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};