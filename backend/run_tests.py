"""Test runner for NeoSpartan Backend."""

import subprocess
import sys
import os

def run_tests():
    """Run all tests with coverage."""
    # Add backend to path
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    
    # Check syntax of all Python files
    print("=" * 60)
    print("Step 1: Checking Python syntax...")
    print("=" * 60)
    
    import py_compile
    errors = []
    
    for root, dirs, files in os.walk('.'):
        # Skip virtual environments and cache
        if any(skip in root for skip in ['venv', '__pycache__', '.git', 'node_modules']):
            continue
        for file in files:
            if file.endswith('.py'):
                filepath = os.path.join(root, file)
                try:
                    py_compile.compile(filepath, doraise=True)
                except py_compile.PyCompileError as e:
                    errors.append(f"{filepath}: {e}")
    
    if errors:
        print("Syntax errors found:")
        for error in errors:
            print(f"  - {error}")
        return False
    else:
        print("All Python files have valid syntax")
    
    # Try to import main modules
    print("\n" + "=" * 60)
    print("Step 2: Testing module imports...")
    print("=" * 60)
    
    modules_to_test = [
        'main',
        'config',
        'database',
        'ai_engine',
        'auth',
        'websocket_manager',
        'worker',
        'migrations',
        'logging_config'
    ]
    
    import_errors = []
    for module in modules_to_test:
        try:
            __import__(module)
            print(f"  {module}: OK")
        except Exception as e:
            import_errors.append(f"{module}: {e}")
            print(f"  {module}: FAILED - {e}")
    
    if import_errors:
        print(f"\nImport errors: {len(import_errors)}")
        return False
    
    # Run pytest if available
    print("\n" + "=" * 60)
    print("Step 3: Running pytest...")
    print("=" * 60)
    
    try:
        result = subprocess.run(
            [sys.executable, '-m', 'pytest', 'tests/', '-v', '--tb=short'],
            capture_output=True,
            text=True,
            timeout=60
        )
        print(result.stdout)
        if result.returncode != 0:
            print("Test failures:")
            print(result.stderr)
            return False
    except subprocess.TimeoutExpired:
        print("Tests timed out")
        return False
    except FileNotFoundError:
        print("pytest not installed, skipping test execution")
        print("Install with: pip install pytest pytest-asyncio httpx")
    
    print("\n" + "=" * 60)
    print("All checks passed!")
    print("=" * 60)
    return True

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
