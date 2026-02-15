import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourapp/utils/api_tester_helper.dart';

class AIOperations {
  late final GenerativeModel model;
  static const String defaultModel = 'gemini-2.5-flash';
  static const String modelKey = 'ai_model';

  AIOperations() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final modelName = prefs.getString(modelKey) ?? defaultModel;
    model = FirebaseAI.googleAI().generativeModel(model: modelName);
  }

  Future<void> updateModel(String modelName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(modelKey, modelName);
    model = FirebaseAI.googleAI().generativeModel(model: modelName);
  }

  static Future<String> getCurrentModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(modelKey) ?? defaultModel;
  }

  Future<String?> fixError(String error, String code) async {
    final fixPrompt = '''
I am an expert JavaScript/React debugging specialist with deep knowledge of React, Tailwind CSS, and browser APIs. I analyze runtime errors, identify root causes, and provide complete working solutions while maintaining the original application architecture and functionality.

TASK:
Fix the JavaScript/React runtime error in the provided code. Identify the exact cause of the error and provide a complete working solution.

ERROR DETAILS:
$error

CURRENT CODE:
$code

EXAMPLE ERROR AND FIX:
Error: "Cannot read property 'map' of undefined"
Code:
const tasks = this.props.items;
return tasks.map(t => <div>{t.name}</div>);

Fixed Code:
const tasks = this.props.items || [];
return (tasks || []).map(t => <div>{t.name}</div>);

Error: "Maximum update depth exceeded"
Code:
function App() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    setCount(count + 1);
  }, [count]);
}

Fixed Code:
function App() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    setCount(prev => prev + 1);
  }, []);
}

Error: "localStorage is not defined"
Code:
useEffect(() => {
  const data = localStorage.getItem('key');
}, []);

Fixed Code:
useEffect(() => {
  if (typeof window !== 'undefined') {
    const data = localStorage.getItem('key');
  }
}, []);

IMPORTANT CONTEXT - Available APIs:
The generated apps run in a WebView with access to these browser/device APIs:
- window.FileHandler.pickFile(options) - Pick files from device
- window.FileHandler.pickFiles(options) - Pick multiple files
- window.FileHandler.saveFile(data, filename) - Save files
- window.FileHandler.getAppDocumentsPath() - Get app directory
- window.FileHandler.requestPermission() - Request media permission
- window.FileHandler.getAllMedia(options) - Query device media library

RESPONSE RULES:
1. Provide the COMPLETE fixed HTML file (the entire code with fixes applied)
2. Fix the ROOT CAUSE, not just the symptoms
3. Ensure the fix doesn't break existing functionality
4. Handle edge cases (null, undefined, empty arrays, etc.)
5. Use optional chaining (?.) and nullish coalescing (??) where appropriate
6. Add proper error boundaries and defensive coding
7. For async operations, ensure proper error handling with try-catch
8. Preserve all existing features and data persistence
9. Do NOT change the overall structure or architecture
10. Do NOT add any explanations - only return the fixed code
11. If the error is in React state management, use proper state immutability patterns
12. For dependency array issues in useEffect, use appropriate dependencies or empty array
13. Ensure all event handlers are properly bound

IMPORTANT: Return ONLY the complete fixed HTML code without any markdown formatting or explanations.
''';

    final content = [Content.text(fixPrompt)];
    final response = await model.generateContent(content);
    return response.text?.trim();
  }

  Future<String?> getPrompt(String prompt) async {
    final fullPrompt = '''
    I am the world's leading expert in mobile app design and system architecture, specializing in creating comprehensive mobile application blueprints. With extensive experience in mobile UI/UX design, accessibility standards, and daisyUI/Tailwind principles, I provide complete, production-ready specifications for mobile-first applications.

    TASK:
    Generate a detailed mobile application specification based on the user's requirements.

    WEBAPP UI THEME REQUIREMENTS:
    - Use daisyUI from CDN with black/white/shadcn-inspired design
    - Primary theme: dark mode with dark gray (#1F2937) background, white text, and gray borders
    - Accessible accent colors: Green (#22C55E) for success/safe, Yellow (#EAB308) for warning, Red (#EF4444) for error/danger
    - Minimal, mobile-responsive design optimized for phone screens
    - Clean, modern aesthetic with subtle shadows and rounded corners
    - All interactive elements must have sufficient color contrast (WCAG AA minimum)
    - Use daisyUI components (btn, card, input, swap, etc.) for consistent UI

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
    - LocalStorage persistence for task data (ALL features must be fully functional with real data persistence)

    ===UI DESIGN===
    Layout:
    - Mobile-first responsive design optimized for phone screens
    - Clean, distraction-free single-page layout
    - NO app bar/top bar - use bottom navigation bar only with 3-5 main sections (NEVER use sidebars)
    - Floating Action Button for primary actions
    - Card-based content with touch-friendly tap targets (minimum 44px)
    - Scrollable content areas with proper spacing
    
    Color Scheme (daisyUI dark theme):
    - Background: #1F2937 (dark gray)
    - Surface: #374151 (lighter gray)
    - Primary Text: #F9FAFB (white)
    - Secondary Text: #9CA3AF (gray)
    - Border: #4B5563 (medium gray)
    - Accent/Primary: #06B6D4 (cyan - daisyUI primary)
    - Success: #22C55E (green)
    - Warning: #EAB308 (yellow)
    - Error: #EF4444 (red)
    
    Components:
    - Bottom Navigation Bar with icons and labels for main sections
    - Subject filter chips with active state indicators
    - Task cards with:
          - Checkbox for completion (large touch target)
          - Progress bar
          - Deadline display
          - Edit button (touch-friendly size)
          - Title and subject display
    - Full-screen modal for task creation/editing
    - Large, touch-friendly form inputs
    - Mobile-optimized buttons and interactive elements

    ===USER FLOWS===
    1. Navigation:
       - Tap bottom nav items to switch between main sections
       - Smooth transitions between views
       - Active section clearly indicated

    2. Task Creation:
       - Tap FAB → Full-screen form opens
       - Fill task details with mobile keyboard support
       - Select subject from dropdown
       - Set deadline using native date/time picker
       - Confirm and see task in list

    3. Task Management:
       - Tap checkbox to complete task
       - Tap edit button for full-screen edit view
       - Tap chips to filter categories
       - Pull to refresh for updates

    User's application idea: $prompt

    RESPONSE RULES:
    1. Validate input against rules first
    2. For invalid inputs, respond only with "no"
    3. For valid inputs, follow exact format above
    4. Design for MOBILE-FIRST: NO app bar/top bar, use bottom navigation only, NO sidebars
    5. All features must be FULLY FUNCTIONAL with real data (NO mock data)
    6. Ensure all UI elements follow daisyUI mobile guidelines
    7. All interactive elements must have touch-friendly sizes (44px minimum)
    8. Include proper mobile gestures and interactions
    9. No explanations or comments in output
    10. Use daisyUI dark theme colors specified above
    11. Keep navigation simple - bottom nav with 3-5 items maximum
    12. Only add features you are CONFIDENT can be implemented - do NOT add features that are uncertain or impossible (e.g., background running, call tracking, real-time GPS tracking of other users, etc.)
    13. Do NOT include hardcoded items or mock data - all data must come from user input or real APIs
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
    I am an expert mobile-first web application architect specializing in creating production-ready, touch-optimized, and performant mobile web applications. With mastery of React, daisyUI, Tailwind CSS, and mobile-first design principles, I deliver complete, fully-functional solutions optimized for mobile devices with NO mock data and ALL features working correctly.

    CRITICAL REQUIREMENTS:
    - MOBILE-FIRST DESIGN: Optimize for phone screens, touch interactions
    - NO APP BAR/TOP BAR: Use bottom navigation bar only - no top app bars needed
    - BOTTOM NAVIGATION ONLY: Never use sidebars or desktop-style navigation
    - NO MOCK DATA: All features must work with real LocalStorage/IndexedDB
    - FULLY FUNCTIONAL: Every feature must work correctly, no placeholders
    - TOUCH-OPTIMIZED: All buttons/inputs minimum 44px, proper spacing
    
    WEBAPP UI THEME - USE daisyUI FROM CDN:
    <link href="https://cdn.jsdelivr.net/npm/daisyui@5/themes.css" rel="stylesheet" type="text/css" />
    <link href="https://cdn.jsdelivr.net/npm/daisyui@5" rel="stylesheet" type="text/css" />
    <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
    
    IMPORTANT: Use daisyUI dark theme (cyberpunk or night) or custom dark theme:
    <html data-theme="night">
    
    Color scheme for accessibility (green/yellow/red for status):
    - Success/Safe: #22C55E (green)
    - Warning: #EAB308 (yellow)  
    - Error/Danger: #EF4444 (red)
    - Background: #1F2937 (dark gray)
    - Surface: #374151 (lighter gray)
    - Primary Text: #F9FAFB (white)
    - Border: #4B5563 (medium gray)
    
    Use daisyUI components: btn, card, input, swap, toggle, navbar, bottom-nav, etc.
    
    EXAMPLE INPUT :
    ===CORE FEATURES===
    - Task management with deadline tracking and completion status
    - Subject-based task categorization
    - Visual progress tracking with percentage indicators
    - LocalStorage persistence for task data (ALL features must be fully functional)

    ===UI DESIGN===
    Layout:
    - Mobile-first responsive design for phone screens
    - NO app bar/top bar - bottom navigation bar only with main sections
    - Floating Action Button for task creation
    - Card-based task list with large touch targets
    
    Color Scheme (daisyUI night theme):
    - Use data-theme="night" for dark mode
    - Success: #22C55E, Warning: #EAB308, Error: #EF4444
    
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
   <html lang="en" data-theme="night">
     <head>
       <meta charset="UTF-8" />
       <meta name="viewport" content="width=device-width, initial-scale=1.0" />
       <title>Student Task Manager</title>
       <!-- daisyUI + Tailwind CSS -->
       <link href="https://cdn.jsdelivr.net/npm/daisyui@5/themes.css" rel="stylesheet" type="text/css" />
       <link href="https://cdn.jsdelivr.net/npm/daisyui@5" rel="stylesheet" type="text/css" />
       <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
       <!-- Google Fonts -->
       <link
         href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap"
         rel="stylesheet"
       />
       <style>
         body {
           font-family: 'Roboto', sans-serif;
         }
         @keyframes slideDown {
           from { transform: translateY(-100%); opacity: 0; }
           to { transform: translateY(0); opacity: 1; }
         }
         .animate-slide-down {
           animation: slideDown 0.3s ease-out;
         }
       </style>
     </head>
     <body class="bg-base-200">
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
               const updatedTasks = tasks.map((t) =>
                 t.id === editingTask.id ? { ...taskForm } : t
               );
               setTasks(updatedTasks);
             } else {
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
             return diff < 24 * 60 * 60 * 1000;
           };
   
           return (
             <div className="min-h-screen pb-20">
               <main className="container mx-auto px-4 py-6">
                 <div className="mb-6">
                   <div className="flex flex-wrap gap-2">
                     <button
                       onClick={() => setSelectedSubject('All')}
                       className={`btn btn-sm \${selectedSubject === 'All' ? 'btn-primary' : 'btn-ghost'}`}
                     >
                       All
                     </button>
                     {subjects.map((subject) => (
                       <button
                         key={subject}
                         onClick={() => setSelectedSubject(subject)}
                         className={`btn btn-sm \${selectedSubject === subject ? 'btn-primary' : 'btn-ghost'}`}
                       >
                         {subject}
                       </button>
                     ))}
                   </div>
                 </div>
   
                 <div className="space-y-4">
                   {filteredTasks.map((task) => (
                     <div
                       key={task.id}
                       className={`card bg-base-300 shadow-md \${task.completed ? 'opacity-60' : ''}`}
                     >
                       <div className="card-body p-4">
                         <div className="flex items-center justify-between">
                           <div className="flex-1">
                             <div className="flex items-center gap-3">
                               <input
                                 type="checkbox"
                                 checked={task.completed}
                                 onChange={() => toggleTask(task)}
                                 className="checkbox checkbox-primary checkbox-sm"
                               />
                               <h3
                                 className={`text-lg font-medium \${task.completed ? 'line-through' : ''}`}
                               >
                                 {task.title}
                               </h3>
                             </div>
                             <p className="text-base-content/60 mt-1">{task.subject}</p>
                             <div className="flex items-center mt-2 gap-2">
                               <progress
                                 className="progress progress-primary w-full max-w-xs"
                                 value={task.progress}
                                 max="100"
                               ></progress>
                               <span className="text-sm text-base-content/60">
                                 {task.progress}%
                               </span>
                             </div>
                           </div>
                           <div className="flex flex-col items-end gap-2">
                             <span
                               className={
                                 isUrgent(task) ? 'text-error text-sm' : 'text-base-content/50 text-sm'
                               }
                             >
                               {formatDeadline(task.deadline)}
                             </span>
                             <button
                               onClick={() => editTask(task)}
                               className="btn btn-ghost btn-xs"
                             >
                               Edit
                             </button>
                           </div>
                         </div>
                       </div>
                     </div>
                   ))}
                 </div>
   
                 {filteredTasks.length === 0 && (
                   <div className="text-center py-12">
                     <p className="text-base-content/50">
                       No tasks found. Add some tasks to get started!
                     </p>
                   </div>
                 )}
   
                 <button
                   onClick={() => setShowTaskModal(true)}
                   className="btn btn-primary btn-circle fixed right-6 bottom-24 shadow-lg"
                 >
                   <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                     <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4" />
                   </svg>
                 </button>
   
                 {showTaskModal && (
                   <div
                     className="fixed inset-0 bg-black/50 flex items-start justify-center pt-4 z-50"
                     onClick={() => setShowTaskModal(false)}
                   >
                     <div
                       className="bg-base-200 rounded-b-2xl p-6 w-full max-w-md animate-slide-down shadow-2xl"
                       onClick={(e) => e.stopPropagation()}
                     >
                       <div className="flex items-center justify-between mb-6">
                         <h2 className="text-xl font-bold">
                           {editingTask ? 'Edit Task' : 'Add New Task'}
                         </h2>
                         <button
                           type="button"
                           onClick={() => setShowTaskModal(false)}
                           className="btn btn-ghost btn-circle btn-sm"
                         >
                           <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                             <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                           </svg>
                         </button>
                       </div>
                       <form onSubmit={saveTask}>
                         <div className="space-y-4">
                           <div className="form-control">
                             <label className="label">
                               <span className="label-text">Title</span>
                             </label>
                             <input
                               type="text"
                               value={taskForm.title}
                               onChange={(e) =>
                                 setTaskForm({ ...taskForm, title: e.target.value })
                               }
                               className="input input-bordered"
                               required
                             />
                           </div>
                           <div className="form-control">
                             <label className="label">
                               <span className="label-text">Subject</span>
                             </label>
                             <select
                               value={taskForm.subject}
                               onChange={(e) =>
                                 setTaskForm({
                                   ...taskForm,
                                   subject: e.target.value,
                                 })
                               }
                               className="select select-bordered"
                             >
                               {subjects.map((subject) => (
                                 <option key={subject} value={subject}>
                                   {subject}
                                 </option>
                               ))}
                             </select>
                           </div>
                           <div className="form-control">
                             <label className="label">
                               <span className="label-text">Deadline</span>
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
                               className="input input-bordered"
                               required
                             />
                           </div>
                           <div className="form-control">
                             <label className="label">
                               <span className="label-text">Progress (%)</span>
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
                               className="input input-bordered"
                             />
                           </div>
                         </div>
                         <div className="mt-6 flex gap-3">
                           <button
                             type="button"
                             onClick={() => setShowTaskModal(false)}
                             className="btn btn-ghost flex-1"
                           >
                             Cancel
                           </button>
                           <button
                             type="submit"
                             className="btn btn-primary flex-1"
                           >
                             Save
                           </button>
                         </div>
                       </form>
                     </div>
                   </div>
                 )}
               </main>
   
               <nav className="btm-nav btm-nav-md bg-base-200 border-t border-base-content/20">
                 <button className="text-primary">
                   <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                     <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                   </svg>
                   <span className="btm-nav-label">Tasks</span>
                 </button>
                 <button className="text-base-content/50">
                   <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                     <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                   </svg>
                   <span className="btm-nav-label">Progress</span>
                 </button>
                 <button className="text-base-content/50">
                   <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                     <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                     <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                   </svg>
                   <span className="btm-nav-label">Settings</span>
                 </button>
               </nav>
             </div>
           );
         }
   
         ReactDOM.render(<TaskManager />, document.getElementById('root'));
       </script>
     </body>
   </html>

    User's system design specification: $prompt

    RESPONSE RULES:
    1. Generate complete, production-ready HTML/React.js/daisyUI code
    2. MUST use daisyUI from CDN as shown above - include themes.css and daisyui@5 CSS
    3. MUST use data-theme="night" or other daisyUI dark theme
    4. MOBILE-FIRST: Design for phone screens first, NO app bar/top bar, use bottom navigation only (NEVER sidebars)
    5. ALL FEATURES FULLY FUNCTIONAL: No mock data, use LocalStorage/IndexedDB for persistence
    6. Implement all core features from the system design completely
    7. Use daisyUI components (btn, card, input, progress, btm-nav, modal, etc.)
    8. NO TODO COMMENTS: Every feature must be fully implemented and working
    9. Touch-optimized UI: All buttons minimum h-12 (48px), inputs minimum h-12, proper spacing for fingers
    10. Bottom navigation bar with btm-nav class, 3-5 items maximum, icons + labels
    11. MODALS: Must slide from TOP (not bottom/center), use items-start and pt-4 positioning, include close button
    12. Implement proper error handling for all operations
    13. Include smooth mobile-friendly animations (add CSS keyframes for slide-down animation)
    14. Use CDN links for any additional libraries needed
    15. Use good coding practices and proper state management
    16. Leverage browser APIs (LocalStorage, IndexedDB, etc.) for data persistence
    17. NO MOCK DATA: All data must persist and be fully functional
    18. Responsive font sizes: body text 16px+, labels 14px+, buttons 16px font
    19. All interactive elements must have active: states for touch feedback
    20. For RSS feeds: Use rss2json.com API (https://api.rss2json.com/v1/api.json?rss_url=YOUR_RSS_URL)
    21. For external API calls: Prefer APIs with CORS support, implement loading states and error handling with retry buttons
    22. COLOR ACCESSIBILITY: Use green (#22C55E) for success/safe, yellow (#EAB308) for warning, red (#EF4444) for error/danger
    23. DEVICE STORAGE ACCESS: Your generated apps CAN access device storage! Use the global 'window.FileHandler' object:
        - window.FileHandler.pickFile(options) - Pick files from device. Options: {type: 'audio'|'video'|'image'|'any', multiple: false}
        - window.FileHandler.pickFiles(options) - Pick multiple files. Options: {type: 'audio'|'video'|'image'|'any', multiple: true}
        - window.FileHandler.saveFile(data, filename) - Save files to device storage
        - window.FileHandler.getAppDocumentsPath() - Get app's documents directory path
        - Returns: Promise with {name, path, size, extension} or null if cancelled
        - Example: const file = await window.FileHandler.pickFile({type: 'audio'});
    
    24. DEVICE MEDIA LIBRARY ACCESS: Your generated apps can query ALL media files on the device! Use:
        - window.FileHandler.requestPermission() - Request media permission first! Returns {granted: boolean}
        - window.FileHandler.getAllMedia(options) - Get media files. Options: {type: 'image'|'video'|'audio'|'all', page: 0, pageSize: 100}
          Returns array of {id, title, type, width, height, duration, createDateTime, modifiedDateTime, path, size}
        - Use pagination for large libraries
        - Example:
          const perm = await window.FileHandler.requestPermission();
          if (perm.granted) {
            const photos = await window.FileHandler.getAllMedia({type: 'image', pageSize: 50});
          }
    
    25. ONLY add features you are CONFIDENT can be implemented - do NOT add features that are uncertain or impossible
    26. Do NOT include hardcoded items or mock data - all data must come from user input or real APIs
    ''';

    final content = [Content.text(fullPrompt)];
    final response = await model.generateContent(content);
    return response.text;
  }

  Future<String?> editCode(String html, String feature) async {
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

  Future<String> validateAndAddApiToSpec({
    required String url,
    required String method,
    String? body,
    required String currentSpec,
  }) async {
    final apiTester = ApiTesterHelper();

    final result = await apiTester.validateApiAgainstSpec(
      url: url,
      method: method,
      body: body,
      specContent: currentSpec,
    );

    if (!result.valid) {
      return 'API_VALIDATION_FAILED: ${result.message}';
    }

    return currentSpec + result.toSpecAddition();
  }

  Future<Map<String, dynamic>?> testApiWithRetry({
    required String url,
    required String method,
    String? body,
  }) async {
    final apiTester = ApiTesterHelper();

    final result = await apiTester.testApi(
      url: url,
      method: method,
      body: body,
    );

    if (result.success) {
      return {
        'success': true,
        'statusCode': result.statusCode,
        'responseData': result.responseData,
        'responseTime': result.responseTime?.inMilliseconds,
      };
    } else {
      return {
        'success': false,
        'error': result.error,
        'attempts': result.attempts,
      };
    }
  }

  static String get apiTestingPrompt => '''
API TESTING AND VALIDATION:
When the user asks to create an app that requires API integration, follow these steps:
1. First, analyze the spec to identify required API endpoints
2. If the user provides API URLs, use the ApiTesterHelper to validate them
3. The helper class will automatically retry up to 3 times if the API fails
4. If API is valid, extract and add the following to the spec:
   - API Structure (REST, GraphQL, etc.)
   - API Type (authentication, paginated, search, standard, list)
   - Input Schema (required parameters)
   - Output Schema (response format)
   - URLs used
5. If API fails after 3 retries, inform the user that the AI API validation failed
6. The API tester can be used as a function call for programmatic validation

Example usage:
final result = await apiTester.validateApiAgainstSpec(
  url: 'https://api.example.com/users',
  method: 'GET',
  specContent: currentSpec,
);

If result.valid is true, use result.toSpecAddition() to add the API details to the spec.
If result.valid is false, inform the user about the failure.
''';
}
