# YourApp

## Overview
YourApp is an AI-powered **mobile IDE and application builder** that allows users to generate fully functional apps within the same app. Instead of searching through app stores for solutions that may lack customization, updates, or essential features, users can create their own tailored applications using a simple prompt-based system. **This is not a one-click app-building solution but more like an AI-based mobile IDE, providing a workspace for generating and refining applications.**

<img src="rss2.gif" alt="YourApp" width="300">


## Approach

1. **AI-Assisted Code Generation**  
   - **Two-Step Prompt Process:**  
     - *Step 1:* The user’s initial prompt is refined to articulate clear app-building instructions.
     - *Step 2:* The refined prompt is fed to an AI engine (e.g., Gemini API or Claude 3.7) to generate a single-file HTML output.  
   - **Output Constraints:**  
     The generated HTML includes inline CSS and JavaScript, ensuring the entire application is bundled in a single file.

2. **Rendering the Application**  
   - The HTML code is sanitized and then displayed using a Flutter WebView.
   - Local storage support is integrated, allowing for data persistence across sessions without platform restrictions.

3. **Customization and Maintenance**  
   - While the concept simplifies app generation, it introduces challenges such as ad management, updating features, and providing extensive customization.
   - A dedicated section in the app stores previously used prompts and saved HTML code, minimizing token usage and offering a streamlined user experience.

## Features
- **AI-Powered Mobile IDE & App Generation**: Users provide a prompt, which is optimized and fed into an AI model to generate a complete HTML-based app.
- **Customization & Editing**: Users can modify prompts and regenerate their apps instantly.
- **Offline Support**: Save generated apps for future use without consuming additional AI tokens.
- **Browser API Integration**: Leverage local storage and other browser capabilities for enhanced functionality.

## Usage
- **Provide an API key** for Gemini AI when launching the app.
- **Enter a prompt** describing the app you want to generate.
- **Wait for AI processing** to generate an optimized HTML-based application.
- **View, edit, and save** the generated app.
- **Access saved apps** from the bottom navigation bar without reusing AI tokens.

## Limitations
- **Complex Applications**: Cannot build sophisticated apps requiring multi-user interactions (e.g., marketplaces) or complex state management.
- **No SVG Support**: Apps that rely on SVG rendering (such as games) may not work properly.
- **Limited AI Accuracy**: Due to using Google Gemini AI (a budget-friendly option), results may sometimes be inaccurate.
- **Bug Handling**: AI-generated code may include errors that require manual debugging.
- **Browser-Based Execution**: Only supports features available in a browser environment.
- **CDN-Only Dependencies**: Cannot use npm packages, limiting available libraries and functionalities.

## How to Contribute
1. **Fork the Repository**: Start by forking the project on GitHub.
2. **Clone the Repository**: Clone it to your local machine using:
   ```sh
   git clone https://github.com/Adhishtanaka/yourapp.git
   ```
3. **Create a Branch**: Create a new branch for your changes:
   ```sh
   git checkout -b feature-branch-name
   ```
4. **Make Changes**: Implement your improvements or bug fixes.
5. **Commit Your Changes**: Write a clear commit message:
   ```sh
   git commit -m "Added feature XYZ"
   ```
6. **Push to GitHub**: Push your changes:
   ```sh
   git push origin feature-branch-name
   ```
7. **Submit a Pull Request**: Open a PR describing your changes.
8. **Review & Merge**: Wait for review and approval before merging.

## Contact
- **Author**: [Adhishtanaka](https://github.com/Adhishtanaka)
- **Email**: kulasoooriyaa@gmail.com

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

