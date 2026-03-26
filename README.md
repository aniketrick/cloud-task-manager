# ☁️ CloudTasks: Serverless Architecture Task Manager

A high-performance, fully serverless task management application built to demonstrate modern full-stack cloud engineering. The entire infrastructure is provisioned as code using **Terraform**, with a **React** frontend hosted on the global edge and a **Node.js** backend powered by AWS serverless technologies.



## 🚀 Features
* **100% Serverless:** Zero servers to manage. Scales infinitely to zero when not in use, meaning practically $0 in running costs.
* **Infrastructure as Code (IaC):** The entire AWS environment (Databases, APIs, CDN, Hosting) is codified using Terraform for one-click deployment and destruction.
* **Global Edge Hosting:** The frontend is stored in a private S3 bucket and distributed globally via AWS CloudFront (CDN) with Origin Access Control (OAC) for maximum security and speed.
* **Modern UI:** Built with React and Tailwind CSS v4, featuring a responsive "Glassmorphism" design.

## 🛠️ Tech Stack

**Frontend**
* React.js (Vite)
* Tailwind CSS v4
* Axios (API communication)
* Lucide-React (Icons)

**Backend & Database (AWS)**
* **API Gateway:** HTTP API for ultra-low latency routing.
* **AWS Lambda:** Node.js functions handling business logic (Create, Read, Delete).
* **DynamoDB:** NoSQL database with On-Demand (PAY_PER_REQUEST) capacity.

**Infrastructure & Hosting**
* **Terraform:** State management and resource provisioning.
* **Amazon S3:** Static asset storage.
* **Amazon CloudFront:** Global Content Delivery Network (CDN) with HTTPS.
* **AWS IAM:** Principle-of-least-privilege execution roles and security policies.

## 📂 Project Structure

```text
cloud-task-manager/
├── frontend/               # React UI, Tailwind config, and Axios calls
├── backend/
│   └── functions/          # Node.js Lambda logic (getTasks, createTask, deleteTask)
└── terraform/              # .tf files defining the entire AWS architecture
