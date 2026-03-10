const API_URL = "https://your-api-id.execute-api.eu-west-2.amazonaws.com"; // PASTE YOUR INVOKE URL HERE

export const addTask = async (title) => {
    try {
        const response = await fetch(`${API_URL}/task`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({ title }),
        });
        return await response.json();
    } catch (error) {
        console.error("Error adding task:", error);
    }
};