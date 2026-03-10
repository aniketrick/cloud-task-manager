import { useState, useEffect } from 'react';
import { addTask, getTasks } from './api';

function App() {
  const [taskTitle, setTaskTitle] = useState("");
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(false);

  // Day 3/4 Roadmap: Fetch tasks from DynamoDB on page load
  useEffect(() => {
    fetchInitialTasks();
  }, []);

  const fetchInitialTasks = async () => {
    const data = await getTasks();
    if (data) {
      setTasks(data);
    }
  };

  const handleCreateTask = async () => {
    if (!taskTitle) return;
    setLoading(true);
    
    // Day 5 Roadmap: Connect React UI to API Gateway POST route
    const result = await addTask(taskTitle);
    
    if (result) {
      setTaskTitle(""); // Clear the input field
      fetchInitialTasks(); // Refresh the list to show the new task
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gray-900 text-white flex flex-col items-center p-10 font-sans">
      <h1 className="text-4xl font-extrabold mb-2 text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-emerald-400">
        Cloud Task Manager
      </h1>
      <p className="text-gray-400 mb-8 italic">Serverless AWS Architecture Demo</p>
      
      {/* Input Section */}
      <div className="flex gap-3 mb-12 w-full max-w-md">
        <input 
          type="text" 
          value={taskTitle}
          onChange={(e) => setTaskTitle(e.target.value)}
          placeholder="What needs to be done?"
          className="flex-1 p-3 rounded-lg bg-gray-800 border border-gray-700 focus:ring-2 focus:ring-blue-500 focus:outline-none transition-all"
        />
        <button 
          onClick={handleCreateTask}
          disabled={loading}
          className="bg-blue-600 hover:bg-blue-500 px-6 py-3 rounded-lg font-bold shadow-lg shadow-blue-900/20 transition-all disabled:opacity-50"
        >
          {loading ? "Saving..." : "Add"}
        </button>
      </div>

      {/* Day 4 Roadmap: Task List Display from DynamoDB */}
      <div className="w-full max-w-md">
        <h2 className="text-xl font-semibold mb-4 text-gray-300 flex items-center gap-2">
          <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
          Active Tasks
        </h2>
        
        {tasks.length === 0 ? (
          <p className="text-gray-500 text-center py-10 bg-gray-800/50 rounded-xl border border-dashed border-gray-700">
            No tasks found. Add one above!
          </p>
        ) : (
          <div className="space-y-3">
            {tasks.map((task) => (
              <div 
                key={task.taskId} 
                className="bg-gray-800 p-4 rounded-xl flex justify-between items-center border border-gray-700 hover:border-blue-500/50 transition-colors shadow-sm"
              >
                <div>
                  <p className="font-medium">{task.title}</p>
                  <p className="text-[10px] text-gray-500 uppercase tracking-widest mt-1">ID: {task.taskId.slice(-6)}</p>
                </div>
                <span className="px-3 py-1 bg-blue-900/30 text-blue-400 text-xs font-bold rounded-full border border-blue-800/50">
                  {task.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;