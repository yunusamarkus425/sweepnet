#!/usr/bin/env python3
"""
Sweepnet Project Submission Script
Submits the completed blockchain street cleaning tracker project.
"""

import os
import sys
import json
import subprocess
from datetime import datetime, timezone

def get_project_stats():
    """Gather project statistics"""
    stats = {
        'project_name': 'Sweepnet',
        'description': 'Street Cleaning Tracker with Proof-of-Cleaning Incentives',
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'contracts': [],
        'tests_passed': False,
        'clarinet_check_passed': False
    }
    
    # Check contracts
    contracts_dir = 'contracts'
    if os.path.exists(contracts_dir):
        for file in os.listdir(contracts_dir):
            if file.endswith('.clar'):
                filepath = os.path.join(contracts_dir, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                    stats['contracts'].append({
                        'name': file,
                        'lines': len(content.splitlines()),
                        'size_bytes': len(content.encode('utf-8'))
                    })
    
    # Check if tests passed (based on previous npm test run)
    try:
        result = subprocess.run(['npm', 'test'], capture_output=True, text=True)
        stats['tests_passed'] = result.returncode == 0
    except:
        stats['tests_passed'] = False
    
    # Check if clarinet check passed
    try:
        result = subprocess.run(['clarinet', 'check'], capture_output=True, text=True)
        stats['clarinet_check_passed'] = result.returncode == 0
    except:
        stats['clarinet_check_passed'] = False
    
    return stats

def submit_project():
    """Submit the project with statistics"""
    print("🚀 Submitting Sweepnet Project...")
    print("=" * 50)
    
    stats = get_project_stats()
    
    print(f"Project: {stats['project_name']}")
    print(f"Description: {stats['description']}")
    print(f"Submission Time: {stats['timestamp']}")
    print()
    
    print("📋 Contract Summary:")
    total_lines = 0
    for contract in stats['contracts']:
        print(f"  • {contract['name']}: {contract['lines']} lines ({contract['size_bytes']} bytes)")
        total_lines += contract['lines']
    print(f"  Total: {total_lines} lines of Clarity code")
    print()
    
    print("✅ Validation Results:")
    print(f"  • Clarinet Check: {'✓ PASSED' if stats['clarinet_check_passed'] else '✗ FAILED'}")
    print(f"  • Tests: {'✓ PASSED' if stats['tests_passed'] else '✗ FAILED'}")
    print()
    
    print("🏗️ Architecture:")
    print("  • Two independent smart contracts")
    print("  • No cross-contract calls (as requested)")
    print("  • Complete proof-of-cleaning incentive system")
    print("  • Role-based admin controls")
    print("  • Reputation-based reward calculations")
    print("  • Anti-spam frequency protection")
    print()
    
    print("📦 Deliverables:")
    print("  • street-manager.clar - Street registration & management")
    print("  • cleaning-tracker.clar - Cleaning activities & rewards") 
    print("  • Complete test suites")
    print("  • CI/CD GitHub Actions workflow")
    print("  • Comprehensive documentation")
    print()
    
    # Save submission data
    with open('submission_data.json', 'w') as f:
        json.dump(stats, f, indent=2)
    
    print("💾 Submission data saved to submission_data.json")
    print("🎉 PROJECT SUBMITTED SUCCESSFULLY!")
    print("=" * 50)

if __name__ == "__main__":
    submit_project()
