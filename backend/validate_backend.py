"""Backend validation script - checks all endpoints and configuration."""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def validate_configuration():
    """Validate configuration settings."""
    print("=" * 60)
    print("Backend Validation Report")
    print("=" * 60)
    
    issues = []
    warnings = []
    
    # Check config
    print("\n[1] Configuration Files")
    print("-" * 40)
    
    config_files = [
        ('config.py', 'Configuration management'),
        ('.env.example', 'Environment variables template'),
        ('requirements.txt', 'Python dependencies'),
    ]
    
    for filename, description in config_files:
        if os.path.exists(filename):
            print(f"  {filename}: Found ({description})")
        else:
            issues.append(f"Missing required file: {filename}")
            print(f"  {filename}: MISSING!")
    
    # Check main modules
    print("\n[2] Core Modules")
    print("-" * 40)
    
    modules = [
        ('main.py', 'FastAPI application with all endpoints'),
        ('database.py', 'Database repositories and Supabase client'),
        ('ai_engine.py', 'Gemini AI and DOM-RL engines'),
        ('auth.py', 'Authentication and JWT handling'),
        ('websocket_manager.py', 'WebSocket connection manager'),
        ('worker.py', 'Background task worker'),
        ('migrations.py', 'Database migration system'),
        ('logging_config.py', 'Logging configuration'),
    ]
    
    for filename, description in modules:
        if os.path.exists(filename):
            size = os.path.getsize(filename)
            print(f"  {filename}: Found ({size} bytes) - {description}")
        else:
            issues.append(f"Missing core module: {filename}")
            print(f"  {filename}: MISSING!")
    
    # Check test suite
    print("\n[3] Test Suite")
    print("-" * 40)
    
    test_files = [
        ('tests/__init__.py', 'Test package init'),
        ('tests/conftest.py', 'Test fixtures'),
        ('tests/test_endpoints.py', 'API endpoint tests'),
    ]
    
    for filename, description in test_files:
        if os.path.exists(filename):
            size = os.path.getsize(filename)
            print(f"  {filename}: Found ({size} bytes)")
        else:
            warnings.append(f"Missing test file: {filename}")
            print(f"  {filename}: Missing (optional)")
    
    # Check deployment files
    print("\n[4] Deployment Configuration")
    print("-" * 40)
    
    deploy_files = [
        ('Dockerfile', 'Main API Docker image'),
        ('docker-compose.yml', 'Docker Compose stack'),
        ('DEPLOYMENT.md', 'Deployment documentation'),
        ('.github/workflows/deploy.yml', 'CI/CD pipeline'),
    ]
    
    for filename, description in deploy_files:
        if os.path.exists(filename):
            print(f"  {filename}: Found ({description})")
        else:
            warnings.append(f"Missing deployment file: {filename}")
            print(f"  {filename}: Missing (optional)")
    
    # Check endpoints in main.py
    print("\n[5] API Endpoints Inventory")
    print("-" * 40)
    
    endpoints = []
    try:
        with open('main.py', 'r') as f:
            content = f.read()
            import re
            
            # Find all @app decorators
            decorators = re.findall(r'@(app\.\w+)\(["\']([^"\']+)', content)
            for dec_type, path in decorators:
                endpoints.append((dec_type.replace('app.', ''), path))
    except Exception as e:
        warnings.append(f"Could not parse endpoints: {e}")
    
    endpoint_categories = {
        'Health': [],
        'Exercises': [],
        'AI': [],
        'DOM-RL': [],
        'Stoic': [],
        'Analytics': [],
        'Warrior': [],
        'Workout Sessions': [],
        'Notifications': [],
        'Progress': [],
        'User': [],
        'Other': []
    }
    
    for method, path in endpoints:
        if 'health' in path:
            endpoint_categories['Health'].append((method, path))
        elif 'exercise' in path:
            endpoint_categories['Exercises'].append((method, path))
        elif 'ai' in path:
            endpoint_categories['AI'].append((method, path))
        elif any(x in path for x in ['dom-rl', 'ephor', 'realtime-adaptation', 'tactical']):
            endpoint_categories['DOM-RL'].append((method, path))
        elif 'stoic' in path:
            endpoint_categories['Stoic'].append((method, path))
        elif 'analytics' in path or 'armor' in path:
            endpoint_categories['Analytics'].append((method, path))
        elif 'warrior' in path or 'achievement' in path or 'chronicle' in path:
            endpoint_categories['Warrior'].append((method, path))
        elif 'workout-session' in path or 'workout_sessions' in path:
            endpoint_categories['Workout Sessions'].append((method, path))
        elif 'notification' in path:
            endpoint_categories['Notifications'].append((method, path))
        elif 'progress' in path or 'personal-record' in path:
            endpoint_categories['Progress'].append((method, path))
        elif 'user' in path or 'ai-memory' in path:
            endpoint_categories['User'].append((method, path))
        else:
            endpoint_categories['Other'].append((method, path))
    
    total_endpoints = 0
    for category, eps in endpoint_categories.items():
        if eps:
            print(f"  {category} ({len(eps)} endpoints):")
            for method, path in eps[:5]:  # Show first 5
                print(f"    - {method.upper()} {path}")
            if len(eps) > 5:
                print(f"    ... and {len(eps) - 5} more")
            total_endpoints += len(eps)
    
    print(f"\n  Total endpoints: {total_endpoints}")
    
    # Summary
    print("\n" + "=" * 60)
    print("Validation Summary")
    print("=" * 60)
    
    if issues:
        print(f"❌ {len(issues)} critical issues found:")
        for issue in issues:
            print(f"  - {issue}")
    
    if warnings:
        print(f"⚠️  {len(warnings)} warnings:")
        for warning in warnings:
            print(f"  - {warning}")
    
    if not issues and not warnings:
        print("✅ All checks passed!")
    
    print("\n" + "=" * 60)
    print("Next Steps:")
    print("=" * 60)
    print("1. Set up environment: cp .env.example .env")
    print("2. Install dependencies: pip install -r requirements.txt")
    print("3. Run tests: python run_tests.py")
    print("4. Start server: uvicorn main:app --reload")
    print("5. Deploy: docker-compose up -d")
    print("=" * 60)
    
    return len(issues) == 0

if __name__ == "__main__":
    success = validate_configuration()
    sys.exit(0 if success else 1)
