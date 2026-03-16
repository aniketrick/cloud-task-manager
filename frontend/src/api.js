const API_URL = "https://lmr5zv0tn6.execute-api.eu-west-2.amazonaws.com/tasks";

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

export const getTasks = async () => {
    try {
        const response = await fetch(`${API_URL}/tasks`); // Note the 's' in /tasks
        return await response.json();
    } catch (error) {
        console.error("Error fetching tasks:", error);
        return [];
    }
};