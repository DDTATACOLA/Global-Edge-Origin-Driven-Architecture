# Global-Edge-Origin-Driven-Architecture
This deployment utilizes a "Secure Origin" pattern, where a global Content Delivery Network (CloudFront) serves as the only entry point for users, communicating with an Application Load Balancer (ALB) via a verified secret header.
