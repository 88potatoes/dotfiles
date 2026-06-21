export enum CommentStatus {
  Active = "active",
  Resolved = "resolved",
}

export type CommentEntity = {
  id: string;
  file: string; // relative to repo root
  startLine: number;
  endLine: number;
  message: string;
  status: CommentStatus;
  createdAt: string;
  updatedAt: string;
}
