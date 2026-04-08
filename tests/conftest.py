"""
Shared pytest fixtures for terraform-azurerm-container-app module tests.

Prerequisites:
  - Azure credentials available via environment variables or az login
  - pip install -r requirements.txt
  - terraform >= 1.5.0 on PATH

Usage:
  pytest tests/ -v
"""

import os
import pytest
import tftest

EXAMPLES_DIR = os.path.join(os.path.dirname(__file__), "..", "examples")
BASIC_EXAMPLE_DIR = os.path.join(EXAMPLES_DIR, "basic")


@pytest.fixture(scope="module")
def basic_plan():
    """Run terraform plan against the basic example and return the plan output."""
    tf = tftest.TerraformTest(BASIC_EXAMPLE_DIR)
    tf.setup()
    yield tf.plan(output=True)
