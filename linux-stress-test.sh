#!/bin/bash

# CPU and Memory Stress Testing Script
# This script provides multiple methods to stress test your Linux instance

set -e

echo "=== EC2 Stress Testing Tools ==="
echo ""

# Function to install stress tools
install_stress_tools() {
    echo "Installing stress testing tools..."

    if command -v yum >/dev/null 2>&1; then
        # Amazon Linux/RHEL/CentOS
        yum update -y
        yum install -y stress stress-ng htop
        amazon-linux-extras install epel -y 2>/dev/null || true
    elif command -v apt >/dev/null 2>&1; then
        # Ubuntu/Debian
        apt update
        apt install -y stress stress-ng htop
    else
        echo "Unsupported package manager. Please install stress tools manually."
        exit 1
    fi
}

# Function to get system info
get_system_info() {
    echo "=== System Information ==="
    echo "CPU Cores: $(nproc)"
    echo "Total Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Available Memory: $(free -h | awk '/^Mem:/ {print $7}')"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
}

# Function for CPU stress testing
cpu_stress_test() {
    local duration=${1:-60}
    local workers=${2:-$(nproc)}

    echo "=== CPU Stress Test ==="
    echo "Duration: ${duration} seconds"
    echo "Workers: ${workers}"
    echo "Starting CPU stress test..."

    # Method 1: Using stress command
    echo "Method 1: Using stress command"
    stress --cpu ${workers} --timeout ${duration}s &
    STRESS_PID=$!

    # Monitor CPU usage
    echo "Monitoring CPU usage (press Ctrl+C to stop monitoring)..."
    while kill -0 $STRESS_PID 2>/dev/null; do
        echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
        sleep 5
    done

    echo "CPU stress test completed."
    echo ""
}

# Function for memory stress testing
memory_stress_test() {
    local duration=${1:-60}
    local memory_mb=${2:-1024}

    echo "=== Memory Stress Test ==="
    echo "Duration: ${duration} seconds"
    echo "Memory to allocate: ${memory_mb}MB"
    echo "Starting memory stress test..."

    # Method 1: Using stress command
    echo "Method 1: Using stress command"
    stress --vm 1 --vm-bytes ${memory_mb}M --timeout ${duration}s &
    STRESS_PID=$!

    # Monitor memory usage
    echo "Monitoring memory usage (press Ctrl+C to stop monitoring)..."
    while kill -0 $STRESS_PID 2>/dev/null; do
        echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
        sleep 5
    done

    echo "Memory stress test completed."
    echo ""
}

# Function for combined stress testing
combined_stress_test() {
    local duration=${1:-60}
    local cpu_workers=${2:-$(nproc)}
    local memory_mb=${3:-1024}

    echo "=== Combined CPU & Memory Stress Test ==="
    echo "Duration: ${duration} seconds"
    echo "CPU Workers: ${cpu_workers}"
    echo "Memory: ${memory_mb}MB"
    echo "Starting combined stress test..."

    # Start both CPU and memory stress
    stress --cpu ${cpu_workers} --vm 1 --vm-bytes ${memory_mb}M --timeout ${duration}s &
    STRESS_PID=$!

    # Monitor both CPU and memory
    echo "Monitoring system resources..."
    while kill -0 $STRESS_PID 2>/dev/null; do
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
        MEM_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
        echo "CPU: ${CPU_USAGE}% | Memory: ${MEM_USAGE}%"
        sleep 5
    done

    echo "Combined stress test completed."
    echo ""
}

# Function to show menu
show_menu() {
    echo "=== Stress Test Options ==="
    echo "1. Install stress tools"
    echo "2. Show system information"
    echo "3. CPU stress test"
    echo "4. Memory stress test"
    echo "5. Combined CPU & Memory stress test"
    echo "6. Custom stress test"
    echo "7. Exit"
    echo ""
}

# Function for custom stress test
custom_stress_test() {
    echo "=== Custom Stress Test Configuration ==="
    read -p "Enter duration in seconds (default: 60): " duration
    duration=${duration:-60}

    read -p "Enter number of CPU workers (default: $(nproc)): " cpu_workers
    cpu_workers=${cpu_workers:-$(nproc)}

    read -p "Enter memory to allocate in MB (default: 1024): " memory_mb
    memory_mb=${memory_mb:-1024}

    echo ""
    echo "Configuration:"
    echo "Duration: ${duration}s"
    echo "CPU Workers: ${cpu_workers}"
    echo "Memory: ${memory_mb}MB"
    echo ""

    read -p "Proceed with this configuration? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        combined_stress_test "$duration" "$cpu_workers" "$memory_mb"
    fi
}

# Main menu loop
while true; do
    show_menu
    read -p "Select an option (1-7): " choice

    case $choice in
        1)
            install_stress_tools
            ;;
        2)
            get_system_info
            ;;
        3)
            echo "CPU Stress Test"
            read -p "Enter duration in seconds (default: 60): " duration
            read -p "Enter number of workers (default: $(nproc)): " workers
            cpu_stress_test "${duration:-60}" "${workers:-$(nproc)}"
            ;;
        4)
            echo "Memory Stress Test"
            read -p "Enter duration in seconds (default: 60): " duration
            read -p "Enter memory in MB (default: 1024): " memory
            memory_stress_test "${duration:-60}" "${memory:-1024}"
            ;;
        5)
            echo "Combined Stress Test"
            read -p "Enter duration in seconds (default: 60): " duration
            combined_stress_test "${duration:-60}"
            ;;
        6)
            custom_stress_test
            ;;
        7)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
    echo ""
done