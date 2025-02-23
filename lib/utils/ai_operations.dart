import 'package:google_generative_ai/google_generative_ai.dart';

class AIOperations {
  late String apiKey;
  late final GenerativeModel model;

  AIOperations({this.apiKey = ''}) {
    model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
    );
  }

  Future<String?> getPrompt(String prompt) async {
    final fullPrompt = '''
    You are a specialized Prompt Generator for software and application development. Your task is to create a structured outline to guide building a new application. Follow these instructions exactly:

    INPUT:
    - Application Idea: A brief description of an application the user wants to build.

    OUTPUT MUST INCLUDE:
    1. Core Features: List 3-5 essential features.
    2. UI/UX Design Concept: Describe the main interface elements including layout and style.
    3. Example User Flows: Provide 2-3 common scenarios demonstrating how users interact with the app.

    RESPONSE FORMAT:
    ===CORE FEATURES===
    - [Feature 1]
    - [Feature 2]
    - [Feature 3]

    ===UI DESIGN===
    - [Layout description]
    - [Color scheme]
    - [Key components]

    ===USER FLOWS===
    1. [User flow 1]
    2. [User flow 2]

    EXAMPLE:
    ===CORE FEATURES===
    - Task creation, editing, and deletion
    - Mark tasks as completed and filter by status
    - Categorize tasks with labels and priorities
    
    ===UI DESIGN===
    - Clean, minimal interface with a focus on usability
    - Primary: #2563eb with neutral backgrounds for clarity
    - Components: Input field for new tasks, a dynamic task list, and filter buttons
    
    ===USER FLOWS===
    1. User enters a new task in the input field and clicks "Add" to see it listed.
    2. User marks a task as completed and filters to view only pending tasks.
    3. User edits an existing task by clicking on it, updating the text, and saving the changes.


    User's application idea: $prompt

    Response rules:
    1. Generate content strictly following the structure above.
    2. Do not include explanations or additional commentary.
    3. If the input is not a valid application idea, respond with "no".
    ''';

    final content = [Content.text(fullPrompt)];
    final response = await model.generateContent(content);
    if (response.text == 'no') {
      return null;
    }
    print(response.text);
    return response.text;
  }

  Future<String?> getCode(String prompt) async {
    final fullPrompt = '''
    You are a specialized SPA Generator for building Single Page Applications using Alpine.js. Generate a complete HTML file scaffold with the following instructions:

    REQUIRED DEPENDENCIES:
    1. Alpine.js: Include via CDN:
       <script src="//unpkg.com/alpinejs" defer></script>
    2. Tailwind CSS: Include via CDN:
       <script src="https://unpkg.com/@tailwindcss/browser@4"></script>

    OUTPUT STRUCTURE:
    1. A complete HTML file including the required dependencies.
    2. A simple SPA structure using Alpine.js for reactivity and state management.
    3. Implement basic routing by conditionally displaying at least two views (e.g., Home and About).
    4. Use Tailwind CSS for styling.
    5. The UI must be mobile-responsive, as this application is intended for mobile use.if you can make it look like material design just using tailwind.

    EXAMPLE OUTPUT:
    <!DOCTYPE html>
    <html lang="en" x-data="app()">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Todo List SPA</title>
      <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
      <script src="//unpkg.com/alpinejs" defer></script>
    </head>
    <body class="bg-gray-50">
      <div class="container mx-auto p-4">
        <nav class="mb-4">
          <button class="mr-2 px-4 py-2 bg-blue-600 text-white" @click="currentView = 'todo'">Todo List</button>
          <button class="px-4 py-2 bg-blue-600 text-white" @click="currentView = 'about'">About</button>
        </nav>
        
        <div x-show="currentView === 'todo'">
          <h1 class="text-2xl font-bold mb-4">Todo List</h1>
          <div class="mb-4">
            <input x-model="newTask" type="text" placeholder="Enter a new task" class="border p-2 w-full">
            <button @click="addTask()" class="mt-2 px-4 py-2 bg-green-600 text-white">Add Task</button>
          </div>
          <ul>
            <template x-for="(task, index) in tasks" :key="index">
              <li class="flex justify-between items-center bg-white p-2 mb-2 shadow">
                <span x-text="task"></span>
                <button @click="removeTask(index)" class="px-2 py-1 bg-red-500 text-white">Delete</button>
              </li>
            </template>
          </ul>
        </div>
        
        <div x-show="currentView === 'about'">
          <h1 class="text-2xl font-bold mb-4">About</h1>
          <p>This is a simple Todo List application built with Alpine.js and styled with Tailwind CSS.</p>
        </div>
      </div>
      
      <script>
        function app() {
          return {
            currentView: 'todo',
            newTask: '',
            tasks: [],
            addTask() {
              if (this.newTask.trim() !== '') {
                this.tasks.push(this.newTask.trim());
                this.newTask = '';
              }
            },
            removeTask(index) {
              this.tasks.splice(index, 1);
            }
          }
        }
      </script>
    </body>
    </html>

    User's application idea: $prompt

    Response rules:
    1. Generate one complete HTML file as described.
    2. Use Alpine.js for reactivity and state management.
    3. Use Tailwind CSS for styling.
    4. Include at least two views/components.
    5. Do not include any commentary beyond the code.
    6. If the input is not a valid application idea, respond with "no".
    ''';

    final content = [Content.text(fullPrompt)];
    final response = await model.generateContent(content);
    print(response.text);
    return response.text;
  }
}
