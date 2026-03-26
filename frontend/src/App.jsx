import React, { useState, useEffect } from "react";
import axios from "axios";
import { Plus, ListCheck, Trash2, Loader2, CheckCircle2, Cloud, Server } from "lucide-react";

// System Configuration
const API_URL = "https://2lj0t0zt3i.execute-api.eu-west-2.amazonaws.com/tasks";
const USER_ID = "123"; 

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [newTaskTitle, setNewTaskTitle] = useState("");
  const [loading, setLoading] = useState(true);
  const [isAdding, setIsAdding] = useState(false);

  // Sync state with AWS DynamoDB on initial page load
  useEffect(() => {
    const fetchTasks = async () => {
      try {
        setLoading(true);
        const response = await axios.get(`${API_URL}?userId=${USER_ID}`);
        setTasks(Array.isArray(response.data) ? response.data : []);
      } catch (error) {
        console.error("Cloud Fetch Error:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchTasks();
  }, []);

  // Handle new task creation and update local state for immediate feedback
  const addTask = async (e) => {
    e.preventDefault();
    if (!newTaskTitle.trim()) return;

    setIsAdding(true);
    try {
      const response = await axios.post(API_URL, {
        userId: USER_ID,
        title: newTaskTitle,
      });
      // Append the new task object returned by the Lambda
      setTasks((prev) => [...prev, response.data.task]);
      setNewTaskTitle("");
    } catch (error) {
      console.error("Task Creation Failed:", error);
    } finally {
      setIsAdding(false);
    }
  };

  // Trigger DELETE request to API Gateway and filter local list upon success
  const deleteTask = async (taskId) => {
    try {
      // Axios DELETE requires the body to be wrapped in a 'data' object
      await axios.delete(API_URL, {
        data: { userId: USER_ID, taskId: taskId }
      });
      setTasks((prev) => prev.filter((t) => t.taskId !== taskId));
    } catch (error) {
      console.error("Cloud Deletion Failed:", error);
    }
  };

  return (
    <div className="min-h-screen bg-[#020617] text-slate-200 font-sans flex justify-center selection:bg-indigo-500/30">
      
      {/* Decorative background elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[500px] h-[500px] bg-indigo-600/10 blur-[120px] rounded-full" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[500px] h-[500px] bg-emerald-600/10 blur-[120px] rounded-full" />
      </div>

      <div className="relative z-10 w-full max-w-2xl px-6 py-16 md:py-24 mx-auto">
        
        <header className="flex flex-col items-center text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-slate-900/80 border border-white/5 text-indigo-400 text-[10px] font-bold uppercase tracking-[0.2em] mb-6 shadow-xl">
            <Server size={12} className="animate-pulse" />
            <span>London Node: Active</span>
          </div>
          
          <h1 className="text-5xl md:text-6xl font-black text-white tracking-tighter mb-4 italic">
            CLOUD<span className="text-indigo-500">TASKS</span>
          </h1>
          <p className="text-slate-500 text-sm md:text-base max-w-sm leading-relaxed">
            A high-performance task engine powered by <span className="text-slate-300">AWS Lambda</span> and <span className="text-slate-300">DynamoDB</span>.
          </p>
        </header>

        <form onSubmit={addTask} className="mb-16">
          <div className="relative group p-[1px] rounded-[2rem] bg-gradient-to-b from-white/10 to-transparent focus-within:from-indigo-500/50 transition-all duration-500 shadow-2xl">
            <div className="relative bg-[#0b1120] rounded-[2rem] p-2 flex items-center">
              <input
                type="text"
                placeholder="Synchronize a new task..."
                value={newTaskTitle}
                onChange={(e) => setNewTaskTitle(e.target.value)}
                className="flex-1 bg-transparent py-4 px-6 focus:outline-none text-white placeholder:text-slate-600 text-lg"
              />
              <button
                type="submit"
                disabled={isAdding || !newTaskTitle.trim()}
                className="h-14 w-14 bg-indigo-600 hover:bg-indigo-500 disabled:bg-slate-800 text-white rounded-2xl transition-all flex items-center justify-center active:scale-90 flex-shrink-0"
              >
                {isAdding ? <Loader2 className="animate-spin" size={24} /> : <Plus size={28} />}
              </button>
            </div>
          </div>
        </form>

        <div className="space-y-4">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-20">
              <Loader2 className="animate-spin text-indigo-500 mb-4" size={40} />
              <span className="text-[10px] font-mono text-slate-500 uppercase tracking-[0.3em]">Querying Database...</span>
            </div>
          ) : tasks.length === 0 ? (
            <div className="text-center py-20 rounded-[2.5rem] border border-white/5 bg-white/[0.02] backdrop-blur-sm">
              <Cloud size={40} className="mx-auto text-slate-800 mb-4" />
              <p className="text-slate-500 font-medium">No active records found.</p>
            </div>
          ) : (
            <div className="grid gap-4">
              {tasks.map((task) => (
                <div 
                  key={task.taskId} 
                  className="group flex items-center justify-between p-6 bg-white/[0.03] hover:bg-white/[0.06] backdrop-blur-md border border-white/5 rounded-[2rem] transition-all duration-300 shadow-sm"
                >
                  <div className="flex items-center gap-6">
                    {/* Visual status indicator */}
                    <div className="w-6 h-6 rounded-full border border-slate-700 flex items-center justify-center group-hover:border-emerald-500 transition-colors duration-500">
                       <CheckCircle2 className="text-emerald-500 scale-0 group-hover:scale-100 transition-transform duration-300" size={16} />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-200 group-hover:text-white transition-colors tracking-tight">
                        {task.title}
                      </h3>
                      <div className="flex items-center gap-3 mt-1.5 font-mono text-[9px] text-slate-600 tracking-widest uppercase">
                        <span>CID: {task.taskId.slice(-8)}</span>
                        <span className="w-1 h-1 rounded-full bg-slate-800" />
                        <span>Status: Verified</span>
                      </div>
                    </div>
                  </div>
                  
                  {/* Delete trigger - Z-index and pointer-events ensure clickability over glass layers */}
                  <button 
                    onClick={() => deleteTask(task.taskId)}
                    className="relative z-20 opacity-0 group-hover:opacity-100 p-2 text-slate-600 hover:text-red-400 transition-all hover:rotate-12 cursor-pointer pointer-events-auto"
                  >
                    <Trash2 size={20} />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        <footer className="mt-24 pt-10 border-t border-white/5 flex flex-col md:flex-row justify-between items-center gap-6 text-[10px] font-mono text-slate-600 tracking-widest uppercase">
          <div className="flex items-center gap-6">
            <span className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]" />
              Engine Secure
            </span>
            <span>API v1.0.4</span>
          </div>
          <p>© 2026 Aniket Chakraborty</p>
        </footer>
      </div>
    </div>
  );
}