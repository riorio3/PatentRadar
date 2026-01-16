# PatentRadar

An iOS app that helps entrepreneurs and inventors discover, analyze, and license government patents for commercialization.

## Features

### Patent Discovery
Browse 600+ patents across 15 categories including Aeronautics, Robotics, Materials, Health, and more. Search by keyword or explore by category.

### AI Problem Solver
Describe a real-world problem in plain English. The app uses AI to find relevant patents and explains how each technology could solve your problem, with relevance scores and implementation ideas.

### Business Analysis
Get AI-powered commercialization analysis for any patent:
- Business ideas and applications
- Target markets
- Competitor analysis
- Implementation roadmap
- Cost estimates

### Licensing Programs
Learn about programs like Startup NASA—qualifying startups can license patents for free for up to 3 years.

## Tech Stack

- **SwiftUI** - iOS 16+
- **Claude AI** - Anthropic's Claude Sonnet for intelligent analysis
- **NASA T2 Portal API** - Patent data from NASA's public Technology Transfer program
- **iOS Keychain** - Secure API key storage

## Project Structure

```
PatentRadar/
├── App/
│   └── PatentRadar.swift             # Entry point, tab navigation, state
├── Features/
│   ├── Discovery/
│   │   ├── DiscoveryView.swift       # Browse & search patents
│   │   ├── PatentCardView.swift      # Patent card UI
│   │   └── SavedPatentsView.swift    # Bookmarked patents
│   ├── PatentDetail/
│   │   ├── PatentDetailView.swift    # Full patent details
│   │   └── MediaViewer.swift         # Image zoom, video links
│   ├── ProblemSolver/
│   │   └── ProblemSolverView.swift   # AI problem matching
│   ├── AIAnalysis/
│   │   └── BusinessAnalysisView.swift # Business intelligence
│   └── Licensing/
│       └── SettingsView.swift        # API key, app settings
└── Services/
    ├── API/
    │   ├── NASAAPI.swift             # NASA T2 Portal integration
    │   └── PatentModels.swift        # Data models
    ├── AI/
    │   └── AIService.swift           # Claude API integration
    └── Storage/
        ├── KeychainService.swift     # Secure storage
        └── ProblemHistoryStore.swift # Search history
```

## Setup

1. Clone the repo
2. Open `PatentRadar.xcodeproj` in Xcode
3. Build and run on iOS 16+ device or simulator
4. Add your Claude API key in Settings to enable AI features

## API Key

AI features (Problem Solver, Business Analysis) require a Claude API key from [Anthropic](https://console.anthropic.com/). The key is stored securely in iOS Keychain and never transmitted anywhere except Anthropic's API.

## Data Source

Patent data comes from [NASA's Technology Transfer Portal](https://technology.nasa.gov/), which provides public access to NASA-developed technologies available for licensing. This app is not affiliated with or endorsed by NASA.

## License

MIT
