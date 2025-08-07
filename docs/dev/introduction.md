# Development Guide - Introduction

Welcome to the Development Guide for Wazuh-docker version 4.13.1. This guide is intended for developers, contributors, and advanced users who wish to understand the development aspects of the Wazuh-Docker project, build custom Docker images, or contribute to its development.

## Purpose of This Guide

The primary goals of this guide are:

-   To provide a clear understanding of the development environment setup.
-   To outline the process for building Wazuh Docker images from source.
-   To explain how to run tests to ensure the integrity and functionality of the images.
-   To offer insights into the project structure and contribution guidelines (though detailed contribution guidelines are typically found in `CONTRIBUTING.md` in the repository).

## Who Should Use This Guide?

This guide is for you if you want to:

-   Modify existing Wazuh Docker images.
-   Build Wazuh Docker images for a specific Wazuh version or with custom configurations.
-   Understand the build process and scripts used in this project.
-   Contribute code, features, or bug fixes to the Wazuh-Docker repository.

## What This Guide Covers

This guide is organized into the following sections:

-   **[Setup Environment](setup.md)**: Instructions on how to prepare your local machine for Wazuh-Docker development, including necessary tools and dependencies.
-   **[Build Image](build-image.md)**: Step-by-step procedures for building the various Wazuh Docker images (Wazuh manager, Wazuh indexer, Wazuh dashboard).
-   **[Run Tests](run-tests.md)**: Information on how to execute automated tests to validate the built images and configurations.

## Prerequisites

Before you begin, it's assumed that you have a basic understanding of:

-   Docker and Docker Compose.
-   Linux command-line interface.
-   Version control systems like Git.
-   The Wazuh platform and its components.

We encourage you to explore the Wazuh-Docker repository and familiarize yourself with its structure. If you plan to contribute, please also review the project's contribution guidelines.
