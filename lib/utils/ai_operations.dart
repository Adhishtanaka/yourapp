import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AIOperations {
  late String apiKey;
  late final GenerativeModel model;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  AIOperations() {
    _initialize();
  }

  Future<void> _initialize() async {
    String? key = await _storage.read(key: "api_key");
    if (key != null) {
      apiKey = key;
      model = GenerativeModel(
        model: 'gemini-3.0-flash',
        apiKey: apiKey,
      );
    } else {
      throw Exception("API key not found!");
    }
  }

  Future<String?> getPrompt(String prompt) async {
    final fullPrompt = '''
    I am the world's leading expert in system design and software architecture, specializing in creating comprehensive application blueprints. With extensive experience in UI/UX design, accessibility standards, and color theory including Material Design principles, I provide complete, production-ready specifications.

    TASK:
    Generate a detailed application specification based on the user's requirements.

    VALIDATION RULES:
    - Must be a valid application development request
    - Must NOT be general programming questions (e.g., "how to center a div")
    - Must NOT be non-software related queries (e.g., "how to make lasagna")

    EXAMPLE INVALID INPUTS AND RESPONSES:
    Input: "How do I center a div?"
    Response: "No"

    Input: "Recipe for pasta"
    Response: "No"

    EXAMPLE VALID INPUT AND OUTPUT:
    Input: "Build a task management app for students"
    Output:
    ===CORE FEATURES===
    - Task management with deadline tracking and completion status
    - Subject-based task categorization
    - Visual progress tracking with percentage indicators
    - LocalStorage persistence for task data

    ===UI DESIGN===
    Layout:
    - Clean, responsive single-page layout
    - Fixed header with app title
    - Floating Action Button for task creation
    - Card-based task list with edit functionality
    
    Color Scheme:
    - Primary: Indigo (#4F46E5)
    - Secondary: Light Gray (#F3F4F6)
    - Background: White (#FFFFFF)
    - Text: Dark Gray (#111827)
    - Accent: Purple for buttons and interactions
    
    Components:
    - Subject filter pills with active state indicators
    - Task cards with:
          - Checkbox for completion
          - Progress bar
          - Deadline display
          - Edit button
          - Title and subject display
    - Modal dialog for task creation/editing
    - Responsive form inputs with validation
    - Interactive elements with hover states

    ===USER FLOWS===
    1. Task Creation:
       - Tap FAB → Fill task details → Select subject
       - Set priority → Add deadline → Confirm (with haptic feedback)
       - View task in relevant category

    2. Task Management:
       - Click checkbox to complete task
       - edit button for detailed edit
       - Click on chips to filter task categories

    User's application idea: $prompt

    RESPONSE RULES:
    1. Validate input against rules first
    2. For invalid inputs, respond only with "no"
    3. For valid inputs, follow exact format above
    4. Include only essential, implementable features
    5. Ensure all UI elements follow Material Design
    6. Maintain accessibility standards in design
    7. No explanations or comments in output
    8. you can decide colors and layout for this application as well.
    9. Prevent UI clutter by limiting app bar elements.
    ''';

    final content = [Content.text(fullPrompt)];
    final response = await model.generateContent(content);
    if (response.text?.trim() == 'No') {
      return null;
    }
    return response.text;
  }

  Future<String?> getCode(String prompt) async {
    final fullPrompt = '''
    I am an expert SPA (Single Page Application) architect specializing in creating production-ready, accessible, and performant web mobile responsive applications. With mastery of React, Tailwind CSS, and Material Design principles, I deliver complete, ready-to-deploy solutions that perfectly match your specifications.

    EXAMPLE INPUT :
    ===CORE FEATURES===
    - Task management with deadline tracking and completion status
    - Subject-based task categorization
    - Visual progress tracking with percentage indicators
    - LocalStorage persistence for task data
    - Simple analytics on task completion rates

    ===UI DESIGN===
    Layout:
    - Clean, responsive single-page layout
    - Fixed header with app title
    - Floating Action Button for task creation
    - Card-based task list with edit functionality
    
    Color Scheme:
    - Primary: Indigo (#4F46E5)
    - Secondary: Light Gray (#F3F4F6)
    - Background: White (#FFFFFF)
    - Text: Dark Gray (#111827)
    - Accent: Purple for buttons and interactions
    
    Components:
    - Subject filter pills with active state indicators
    - Task cards with:
          - Checkbox for completion
          - Progress bar
          - Deadline display
          - Edit button
          - Title and subject display
    - Modal dialog for task creation/editing
    - Responsive form inputs with validation
    - Interactive elements with hover states
    
    ===USER FLOWS===
    1. Task Creation:
       - Tap FAB → Fill task details → Select subject
       - Set priority → Add deadline → Confirm (with haptic feedback)
       - View task in relevant category

    2. Task Management:
       - Click checkbox to complete task
       - edit button for detailed edit
       - Click on chips to filter task categories

    EXAMPLE OUTPUT:
   <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Student Task Manager</title>
        <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>
        <!-- Google Fonts -->
        <link
          href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap"
          rel="stylesheet"
        />
        <style>
          body {
            font-family: 'Roboto', sans-serif;
          }
        </style>
      </head>
      <body class="bg-gray-100">
        <div id="root"></div>
    
        <!-- React and ReactDOM via CDN -->
        <script
          crossorigin
          src="https://unpkg.com/react@17/umd/react.development.js"
        ></script>
        <script
          crossorigin
          src="https://unpkg.com/react-dom@17/umd/react-dom.development.js"
        ></script>
        <!-- Babel CDN for JSX support -->
        <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    
        <!-- React Code -->
        <script type="text/babel">
          const { useState, useEffect, useMemo } = React;
    
          function TaskManager() {
            const [tasks, setTasks] = useState([]);
            const subjects = ['Math', 'Science', 'English', 'History', 'Programming'];
            const [selectedSubject, setSelectedSubject] = useState('All');
            const [showTaskModal, setShowTaskModal] = useState(false);
            const [editingTask, setEditingTask] = useState(null);
            const [taskForm, setTaskForm] = useState({
              id: null,
              title: '',
              subject: 'Math',
              deadline: '',
              progress: 0,
              completed: false,
            });
    
            // Load tasks from localStorage on mount
            useEffect(() => {
              const savedTasks = localStorage.getItem('tasks');
              if (savedTasks) {
                setTasks(JSON.parse(savedTasks));
              }
            }, []);
    
            // Update localStorage when tasks change
            useEffect(() => {
              localStorage.setItem('tasks', JSON.stringify(tasks));
            }, [tasks]);
    
            const filteredTasks = useMemo(() => {
              return selectedSubject === 'All'
                ? tasks
                : tasks.filter((task) => task.subject === selectedSubject);
            }, [tasks, selectedSubject]);
    
            const saveTask = (e) => {
              e.preventDefault();
              if (editingTask) {
                // Update existing task
                const updatedTasks = tasks.map((t) =>
                  t.id === editingTask.id ? { ...taskForm } : t
                );
                setTasks(updatedTasks);
              } else {
                // Add new task
                setTasks([...tasks, { ...taskForm, id: Date.now() }]);
              }
              resetForm();
              setShowTaskModal(false);
            };
    
            const editTask = (task) => {
              setEditingTask(task);
              setTaskForm({ ...task });
              setShowTaskModal(true);
            };
    
            const resetForm = () => {
              setEditingTask(null);
              setTaskForm({
                id: null,
                title: '',
                subject: 'Math',
                deadline: '',
                progress: 0,
                completed: false,
              });
            };
    
            const toggleTask = (task) => {
              const updatedTasks = tasks.map((t) => {
                if (t.id === task.id) {
                  return {
                    ...t,
                    completed: !t.completed,
                    progress: !t.completed ? 100 : 0,
                  };
                }
                return t;
              });
              setTasks(updatedTasks);
            };
    
            const formatDeadline = (deadline) => {
              const date = new Date(deadline);
              return date.toLocaleString('en-US', {
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
              });
            };
    
            const isUrgent = (task) => {
              const deadline = new Date(task.deadline);
              const now = new Date();
              const diff = deadline - now;
              return diff < 24 * 60 * 60 * 1000; // Less than 24 hours
            };
    
            return (
              <div className="min-h-screen">
                {/* Header */}
                <header className="bg-indigo-600 shadow-lg">
                  <div className="container mx-auto px-4 py-6">
                    <h1 className="text-2xl font-bold text-white">
                      Student Task Manager
                    </h1>
                  </div>
                </header>
    
                {/* Main Content */}
                <main className="container mx-auto px-4 py-8">
                  {/* Task Filters */}
                  <div className="mb-6">
                    <div className="flex space-x-2 overflow-x-auto pb-2">
                      <button
                        onClick={() => setSelectedSubject('All')}
                        className={`px-4 py-2 rounded-full shadow hover:shadow-md transition \${
            selectedSubject === 'All'
        ? 'bg-indigo-600 text-white'
            : 'bg-white text-gray-700'
        }`}
                      >
                        All
                      </button>
                      {subjects.map((subject) => (
                        <button
                          key={subject}
                          onClick={() => setSelectedSubject(subject)}
                          className={`px-4 py-2 rounded-full shadow hover:shadow-md transition \${
        selectedSubject === subject
        ? 'bg-indigo-600 text-white'
            : 'bg-white text-gray-700'
        }`}
                        >
                          {subject}
                        </button>
                      ))}
                    </div>
                  </div>
    
                  {/* Task List */}
                  <div className="space-y-4">
                    {filteredTasks.map((task) => (
                      <div
                        key={task.id}
                        className={`bg-white rounded-lg shadow-md p-4 transition-all \${
        task.completed ? 'opacity-75' : ''
        }`}
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex-1">
                            <div className="flex items-center">
                              <input
                                type="checkbox"
                                checked={task.completed}
                                onChange={() => toggleTask(task)}
                                className="h-4 w-4 text-indigo-600 rounded"
                              />
                              <h3
                                className={`ml-3 text-lg font-medium \${
        task.completed ? 'line-through' : ''
        }`}
                              >
                                {task.title}
                              </h3>
                            </div>
                            <p className="text-gray-600 mt-1">{task.subject}</p>
                            <div className="flex items-center mt-2">
                              <div className="w-full bg-gray-200 rounded-full h-2">
                                <div
                                  className="bg-indigo-600 h-2 rounded-full transition-all"
                                  style={{ width:`\${task.progress}%` }}
                                ></div>
                              </div>
                              <span className="ml-2 text-sm text-gray-600">
                                {task.progress}%
                              </span>
                            </div>
                          </div>
                          <div className="ml-4 flex flex-col items-end">
                            <span
                              className={
                                isUrgent(task) ? 'text-red-500' : 'text-gray-500'
                              }
                            >
                              {formatDeadline(task.deadline)}
                            </span>
                            <button
                              onClick={() => editTask(task)}
                              className="mt-2 text-sm text-indigo-600 hover:text-indigo-800"
                            >
                              Edit
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
    
                  {/* Empty State */}
                  {filteredTasks.length === 0 && (
                    <div className="text-center py-12">
                      <p className="text-gray-500">
                        No tasks found. Add some tasks to get started!
                      </p>
                    </div>
                  )}
    
                  {/* Add Task Button */}
                  <button
                    onClick={() => setShowTaskModal(true)}
                    className="fixed right-6 bottom-6 w-14 h-14 bg-indigo-600 rounded-full shadow-lg flex items-center justify-center text-white hover:bg-indigo-700 transition"
                  >
                    <svg
                      className="w-6 h-6"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="2"
                        d="M12 4v16m8-8H4"
                      />
                    </svg>
                  </button>
    
                  {/* Task Modal */}
                  {showTaskModal && (
                    <div
                      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4"
                      onClick={() => setShowTaskModal(false)}
                    >
                      <div
                        className="bg-white rounded-lg p-6 w-full max-w-md"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <h2 className="text-xl font-bold mb-4">
                          {editingTask ? 'Edit Task' : 'Add New Task'}
                        </h2>
                        <form onSubmit={saveTask}>
                          <div className="space-y-4">
                            <div>
                              <label className="block text-sm font-medium text-gray-700">
                                Title
                              </label>
                              <input
                                type="text"
                                value={taskForm.title}
                                onChange={(e) =>
                                  setTaskForm({ ...taskForm, title: e.target.value })
                                }
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                required
                              />
                            </div>
                            <div>
                              <label className="block text-sm font-medium text-gray-700">
                                Subject
                              </label>
                              <select
                                value={taskForm.subject}
                                onChange={(e) =>
                                  setTaskForm({
                                    ...taskForm,
                                    subject: e.target.value,
                                  })
                                }
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                              >
                                {subjects.map((subject) => (
                                  <option key={subject} value={subject}>
                                    {subject}
                                  </option>
                                ))}
                              </select>
                            </div>
                            <div>
                              <label className="block text-sm font-medium text-gray-700">
                                Deadline
                              </label>
                              <input
                                type="datetime-local"
                                value={taskForm.deadline}
                                onChange={(e) =>
                                  setTaskForm({
                                    ...taskForm,
                                    deadline: e.target.value,
                                  })
                                }
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                required
                              />
                            </div>
                            <div>
                              <label className="block text-sm font-medium text-gray-700">
                                Progress (%)
                              </label>
                              <input
                                type="number"
                                value={taskForm.progress}
                                onChange={(e) =>
                                  setTaskForm({
                                    ...taskForm,
                                    progress: parseInt(e.target.value) || 0,
                                  })
                                }
                                min="0"
                                max="100"
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                              />
                            </div>
                          </div>
                          <div className="mt-6 flex justify-end space-x-3">
                            <button
                              type="button"
                              onClick={() => setShowTaskModal(false)}
                              className="px-4 py-2 text-gray-700 hover:text-gray-900"
                            >
                              Cancel
                            </button>
                            <button
                              type="submit"
                              className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
                            >
                              Save
                            </button>
                          </div>
                        </form>
                      </div>
                    </div>
                  )}
                </main>
              </div>
            );
          }
    
          ReactDOM.render(<TaskManager />, document.getElementById('root'));
        </script>
      </body>
    </html>

    User's system design specification: $prompt

    RESPONSE RULES:
    1. Generate complete, production-ready HTML/React.js/Tailwind code
    2. Implement all core features from the system design
    3. Follow Material Design principles using Tailwind classes
    4. Include all required functionality (no TODO comments)
    5. Ensure mobile-first responsive design so small font,button size.  
    6. Add confirmation dialogs for critical actions
    7. Implement proper error handling
    8. Include smooth animations and transitions
    9. You can add any library using cdn link adding to html code
    10. Use good coding practice
    11. also you can use any browser api.
    ''';

    final content = [Content.text(fullPrompt)];
    final response = await model.generateContent(content);
    return response.text;
  }

  Future<String?> editCode(String html,String feature) async {
    final prompt = '''
    I am an expert code modification specialist focusing on enhancing and extending existing applications. I transform your change requests into complete, production-ready implementations while maintaining the original architecture, style, and best practices.
  
    EXAMPLE INPUT:
    ===CURRENT CODE===
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Simple Todo App</title>
        <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>
        <!-- Google Fonts -->
        <link
          href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap"
          rel="stylesheet"
        />
        <style>
          body {
            font-family: 'Roboto', sans-serif;
          }
        </style>
      </head>
      <body class="bg-gray-100">
        <div id="root"></div>
    
        <!-- React and ReactDOM via CDN -->
        <script
          crossorigin
          src="https://unpkg.com/react@17/umd/react.development.js"
        ></script>
        <script
          crossorigin
          src="https://unpkg.com/react-dom@17/umd/react-dom.development.js"
        ></script>
        <!-- Babel CDN for JSX support -->
        <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    
        <!-- React Code -->
        <script type="text/babel">
          const { useState, useEffect } = React;
    
          function TodoApp() {
            const [todos, setTodos] = useState([]);
            const [inputValue, setInputValue] = useState('');
    
            useEffect(() => {
              const savedTodos = localStorage.getItem('todos');
              if (savedTodos) {
                setTodos(JSON.parse(savedTodos));
              }
            }, []);
    
            useEffect(() => {
              localStorage.setItem('todos', JSON.stringify(todos));
            }, [todos]);
    
            const addTodo = (e) => {
              e.preventDefault();
              if (!inputValue.trim()) return;
              
              const newTodo = {
                id: Date.now(),
                text: inputValue,
                completed: false
              };
              
              setTodos([...todos, newTodo]);
              setInputValue('');
            };
    
            const toggleTodo = (id) => {
              const updatedTodos = todos.map(todo => 
                todo.id === id ? { ...todo, completed: !todo.completed } : todo
              );
              setTodos(updatedTodos);
            };
    
            const deleteTodo = (id) => {
              const updatedTodos = todos.filter(todo => todo.id !== id);
              setTodos(updatedTodos);
            };
    
            return (
              <div className="max-w-md mx-auto mt-10 p-6 bg-white rounded-lg shadow-lg">
                <h1 className="text-2xl font-bold text-center mb-6">Todo App</h1>
                
                <form onSubmit={addTodo} className="mb-4">
                  <div className="flex">
                    <input
                      type="text"
                      value={inputValue}
                      onChange={(e) => setInputValue(e.target.value)}
                      className="flex-1 p-2 border rounded-l focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Add a new todo..."
                    />
                    <button
                      type="submit"
                      className="bg-blue-500 text-white px-4 py-2 rounded-r hover:bg-blue-600"
                    >
                      Add
                    </button>
                  </div>
                </form>
                
                <ul className="space-y-2">
                  {todos.map((todo) => (
                    <li 
                      key={todo.id}
                      className="flex items-center justify-between p-3 bg-gray-50 rounded shadow-sm"
                    >
                      <div className="flex items-center">
                        <input
                          type="checkbox"
                          checked={todo.completed}
                          onChange={() => toggleTodo(todo.id)}
                          className="mr-2"
                        />
                        <span className={todo.completed ? 'line-through text-gray-500' : ''}>
                          {todo.text}
                        </span>
                      </div>
                      <button
                        onClick={() => deleteTodo(todo.id)}
                        className="text-red-500 hover:text-red-700"
                      >
                        Delete
                      </button>
                    </li>
                  ))}
                </ul>
                
                {todos.length === 0 && (
                  <p className="text-center text-gray-500 mt-4">No todos yet. Add one above!</p>
                )}
              </div>
            );
          }
    
          ReactDOM.render(<TodoApp />, document.getElementById('root'));
        </script>
      </body>
    </html>

  ===REQUESTED CHANGES===
  Please add priority levels (High, Medium, Low) to todos with color coding and the ability to filter todos by priority and completion status.

  EXAMPLE OUTPUT:
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Enhanced Todo App</title>
      <!-- Tailwind CSS -->
      <script src="https://cdn.tailwindcss.com"></script>
      <!-- Google Fonts -->
      <link
        href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap"
        rel="stylesheet"
      />
      <style>
        body {
          font-family: 'Roboto', sans-serif;
        }
      </style>
    </head>
    <body class="bg-gray-100">
      <div id="root"></div>
  
      <!-- React and ReactDOM via CDN -->
      <script
        crossorigin
        src="https://unpkg.com/react@17/umd/react.development.js"
      ></script>
      <script
        crossorigin
        src="https://unpkg.com/react-dom@17/umd/react-dom.development.js"
      ></script>
      <!-- Babel CDN for JSX support -->
      <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  
      <!-- React Code -->
      <script type="text/babel">
        const { useState, useEffect } = React;
  
        function TodoApp() {
          const [todos, setTodos] = useState([]);
          const [inputValue, setInputValue] = useState('');
          const [priority, setPriority] = useState('Medium');
          const [filterPriority, setFilterPriority] = useState('All');
          const [filterStatus, setFilterStatus] = useState('All');
          
          const priorities = ['High', 'Medium', 'Low'];
          const priorityColors = {
            High: 'bg-red-100 border-red-300',
            Medium: 'bg-yellow-100 border-yellow-300',
            Low: 'bg-green-100 border-green-300'
          };
  
          useEffect(() => {
            const savedTodos = localStorage.getItem('todos');
            if (savedTodos) {
              setTodos(JSON.parse(savedTodos));
            }
          }, []);
  
          useEffect(() => {
            localStorage.setItem('todos', JSON.stringify(todos));
          }, [todos]);
  
          const addTodo = (e) => {
            e.preventDefault();
            if (!inputValue.trim()) return;
            
            const newTodo = {
              id: Date.now(),
              text: inputValue,
              completed: false,
              priority: priority
            };
            
            setTodos([...todos, newTodo]);
            setInputValue('');
          };
  
          const toggleTodo = (id) => {
            const updatedTodos = todos.map(todo => 
              todo.id === id ? { ...todo, completed: !todo.completed } : todo
            );
            setTodos(updatedTodos);
          };
  
          const deleteTodo = (id) => {
            const updatedTodos = todos.filter(todo => todo.id !== id);
            setTodos(updatedTodos);
          };
          
          const changePriority = (id, newPriority) => {
            const updatedTodos = todos.map(todo => 
              todo.id === id ? { ...todo, priority: newPriority } : todo
            );
            setTodos(updatedTodos);
          };
          
          const filteredTodos = todos.filter(todo => {
            const priorityMatch = filterPriority === 'All' || todo.priority === filterPriority;
            const statusMatch = filterStatus === 'All' || 
                               (filterStatus === 'Active' && !todo.completed) ||
                               (filterStatus === 'Completed' && todo.completed);
            return priorityMatch && statusMatch;
          });
  
          return (
            <div className="max-w-md mx-auto mt-10 p-6 bg-white rounded-lg shadow-lg">
              <h1 className="text-2xl font-bold text-center mb-6">Todo App</h1>
              
              <form onSubmit={addTodo} className="mb-4">
                <div className="flex mb-2">
                  <input
                    type="text"
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    className="flex-1 p-2 border rounded-l focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Add a new todo..."
                  />
                  <button
                    type="submit"
                    className="bg-blue-500 text-white px-4 py-2 rounded-r hover:bg-blue-600"
                  >
                    Add
                  </button>
                </div>
                
                <div className="flex items-center space-x-2">
                  <label className="text-sm text-gray-600">Priority:</label>
                  <select 
                    value={priority}
                    onChange={(e) => setPriority(e.target.value)}
                    className="p-1 border rounded text-sm"
                  >
                    {priorities.map(p => (
                      <option key={p} value={p}>{p}</option>
                    ))}
                  </select>
                </div>
              </form>
              
              <div className="mb-4 flex flex-wrap gap-2">
                <div className="w-full sm:w-auto">
                  <label className="text-sm text-gray-600 mr-2">Filter Priority:</label>
                  <select 
                    value={filterPriority}
                    onChange={(e) => setFilterPriority(e.target.value)}
                    className="p-1 border rounded text-sm"
                  >
                    <option value="All">All</option>
                    {priorities.map(p => (
                      <option key={p} value={p}>{p}</option>
                    ))}
                  </select>
                </div>
                
                <div className="w-full sm:w-auto">
                  <label className="text-sm text-gray-600 mr-2">Filter Status:</label>
                  <select 
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="p-1 border rounded text-sm"
                  >
                    <option value="All">All</option>
                    <option value="Active">Active</option>
                    <option value="Completed">Completed</option>
                  </select>
                </div>
              </div>
              
              <ul className="space-y-2">
                {filteredTodos.map((todo) => (
                  <li 
                    key={todo.id}
                    className={`flex items-center justify-between p-3 rounded shadow-sm border \${priorityColors[todo.priority]}`}
                  >
                    <div className="flex items-center">
                      <input
                        type="checkbox"
                        checked={todo.completed}
                        onChange={() => toggleTodo(todo.id)}
                        className="mr-2"
                      />
                      <span className={todo.completed ? 'line-through text-gray-500' : ''}>
                        {todo.text}
                      </span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <select
                        value={todo.priority}
                        onChange={(e) => changePriority(todo.id, e.target.value)}
                        className="text-sm p-1 border rounded"
                      >
                        {priorities.map(p => (
                          <option key={p} value={p}>{p}</option>
                        ))}
                      </select>
                      <button
                        onClick={() => deleteTodo(todo.id)}
                        className="text-red-500 hover:text-red-700"
                      >
                        Delete
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
              
              {filteredTodos.length === 0 && (
                <p className="text-center text-gray-500 mt-4">
                  {todos.length === 0 ? "No todos yet. Add one above!" : "No todos match your filters."}
                </p>
              )}
            </div>
          );
        }
  
        ReactDOM.render(<TodoApp />, document.getElementById('root'));
      </script>
    </body>
  </html>

  ===CURRENT CODE===
  $html

  ===REQUESTED CHANGES===
  $feature

  RESPONSE RULES:
  1. Provide the COMPLETE updated code with all changes fully implemented
  2. Maintain the existing code style, architecture, and naming conventions
  3. Implement all requested features completely (no TODOs or placeholders)
  4. Ensure backward compatibility with existing functionality
  5. Preserve existing imports, dependencies, and library usage
  6. Add proper error handling for new functionality
  7. Include appropriate comments for significant changes
  8. Ensure all new UI elements match the existing design language
  9. Optimize for performance and maintainability
  10. Do not explain the changes in your response - just provide the complete updated code

  IMPORTANT: The response must be the complete, ready-to-use code with all changes fully implemented.
  ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text;
    }
}
