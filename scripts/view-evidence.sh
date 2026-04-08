#!/bin/bash
# View Evidence Script
# Opens evidence directories or displays evidence information

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
EVIDENCE_ROOT="${PROJECT_DIR}/evidence"

# ============================================================
# FUNCTIONS
# ============================================================

list_evidence() {
    echo "=========================================="
    echo "Evidence Directory Listing"
    echo "=========================================="
    echo ""
    
    echo "Paper A: Resource Contention Analysis"
    echo "--------------------------------------"
    
    if [ -d "${EVIDENCE_ROOT}/baseline" ]; then
        BASELINE_FILES=$(find "${EVIDENCE_ROOT}/baseline" -type f | wc -l)
        echo "  baseline/       ${BASELINE_FILES} files"
        ls -la "${EVIDENCE_ROOT}/baseline/" 2>/dev/null | head -5
    fi
    
    if [ -d "${EVIDENCE_ROOT}/contention" ]; then
        CONTENTION_FILES=$(find "${EVIDENCE_ROOT}/contention" -type f | wc -l)
        echo "  contention/    ${CONTENTION_FILES} files"
    fi
    
    if [ -d "${EVIDENCE_ROOT}/throttling" ]; then
        THROTTLING_FILES=$(find "${EVIDENCE_ROOT}/throttling" -type f | wc -l)
        echo "  throttling/    ${THROTTLING_FILES} files"
    fi
    
    echo ""
    echo "Paper B: SPOF Mitigation"
    echo "--------------------------------------"
    
    if [ -d "${EVIDENCE_ROOT}/spof" ]; then
        SPOF_FILES=$(find "${EVIDENCE_ROOT}/spof" -type f | wc -l)
        echo "  spof/          ${SPOF_FILES} files"
        ls -la "${EVIDENCE_ROOT}/spof/" 2>/dev/null
    fi
    
    echo ""
    echo "Collections:"
    echo "--------------------------------------"
    ls -la "${EVIDENCE_ROOT}"/*.tar.gz 2>/dev/null || echo "  No collections archived"
}

open_evidence() {
    PAPER=$1
    PHASE=$2
    
    case "${PAPER}" in
        paper-a|a)
            case "${PHASE}" in
                baseline|fase-1)
                    DIR="${EVIDENCE_ROOT}/baseline"
                    ;;
                contention|fase-2)
                    DIR="${EVIDENCE_ROOT}/contention"
                    ;;
                throttling|fase-3)
                    DIR="${EVIDENCE_ROOT}/throttling"
                    ;;
                *)
                    DIR="${EVIDENCE_ROOT}"
                    ;;
            esac
            ;;
        paper-b|b)
            case "${PHASE}" in
                scenario-1|arch)
                    DIR="${EVIDENCE_ROOT}/spof/scenario-1"
                    ;;
                scenario-2|timeout)
                    DIR="${EVIDENCE_ROOT}/spof/scenario-2"
                    ;;
                scenario-3|healthcheck)
                    DIR="${EVIDENCE_ROOT}/spof/scenario-3"
                    ;;
                *)
                    DIR="${EVIDENCE_ROOT}/spof"
                    ;;
            esac
            ;;
        *)
            DIR="${EVIDENCE_ROOT}"
            ;;
    esac
    
    if [ -d "${DIR}" ]; then
        echo "Opening: ${DIR}"
        if command -v xdg-open &> /dev/null; then
            xdg-open "${DIR}"
        elif command -v open &> /dev/null; then
            open "${DIR}"
        else
            ls -la "${DIR}"
        fi
    else
        echo "Error: Directory not found: ${DIR}"
        echo "Available directories:"
        find "${EVIDENCE_ROOT}" -type d -maxdepth 3
    fi
}

show_manifest() {
    PAPER=$1
    PHASE=$2
    
    case "${PAPER}" in
        paper-a|a)
            MANIFEST="${EVIDENCE_ROOT}/${PHASE}/MANIFEST.md"
            ;;
        paper-b|b)
            MANIFEST="${EVIDENCE_ROOT}/spof/${PHASE}/MANIFEST.md"
            ;;
        *)
            MANIFEST="${EVIDENCE_ROOT}/MANIFEST.md"
            ;;
    esac
    
    if [ -f "${MANIFEST}" ]; then
        echo "=========================================="
        echo "Evidence Manifest"
        echo "=========================================="
        cat "${MANIFEST}"
    else
        echo "Error: Manifest not found: ${MANIFEST}"
    fi
}

# ============================================================
# MAIN
# ============================================================

case "${1}" in
    list|ls)
        list_evidence
        ;;
    view|open)
        open_evidence "${2}" "${3}"
        ;;
    manifest|show)
        show_manifest "${2}" "${3}"
        ;;
    help|--help|-h)
        echo "Usage: $0 {list|view|manifest} [paper] [phase]"
        echo ""
        echo "Commands:"
        echo "  list              List all evidence directories"
        echo "  view <paper> <phase>  Open evidence directory"
        echo "  manifest <paper> <phase>  Show evidence manifest"
        echo ""
        echo "Papers:"
        echo "  paper-a, a        Resource Contention Analysis"
        echo "  paper-b, b        SPOF Mitigation"
        echo ""
        echo "Phases (Paper A):"
        echo "  baseline, fase-1  Baseline testing"
        echo "  contention, fase-2  Contention testing"
        echo "  throttling, fase-3  Throttling analysis"
        echo ""
        echo "Scenarios (Paper B):"
        echo "  scenario-1, arch    Architecture SPOF"
        echo "  scenario-2, timeout  Timeout analysis"
        echo "  scenario-3, healthcheck  Healthcheck test"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 view paper-a baseline"
        echo "  $0 view paper-b scenario-1"
        echo "  $0 manifest paper-a contention"
        ;;
    *)
        list_evidence
        ;;
esac