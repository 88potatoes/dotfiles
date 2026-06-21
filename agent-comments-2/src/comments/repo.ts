import { db } from "../../lib/db.ts";
import { Comment, CreateCommentInput, UpdateCommentInput } from "./comments.table.ts";


export class CommentRepo {
  private db: typeof db;

  private constructor() {
    this.db = db;
  }

  public static readonly instance = new CommentRepo();

  async getCommentById(id: string): Promise<Comment> {
    const comment = this.db.data.comments.find((comment) => comment.id === id);
    if (!comment) {
      throw new Error(`Comment with id ${id} not found`);
    }
    return comment;
  }

  async getAllComments(): Promise<Comment[]> {
    return this.db.data.comments;
  }

  async createComment(comment: CreateCommentInput): Promise<void> {
    const now = new Date().toISOString();
    this.db.data.comments.push({ ...comment, id: crypto.randomUUID(), createdAt: now, updatedAt: now });
    await this.db.write();
  }

  async updateComment(updateCommentPayload: UpdateCommentInput): Promise<void> {
    const index = this.db.data.comments.findIndex((c) => c.id === updateCommentPayload.id);
    if (index === -1) {
      throw new Error(`Comment with id ${updateCommentPayload.id} not found`);
    }

    const { id, ...updates } = updateCommentPayload;

    const now = new Date().toISOString();
    const updatedComment = { ...this.db.data.comments[index], ...updates, updatedAt: now };
    this.db.data.comments[index] = updatedComment;
    await this.db.write();
  }

  async deleteComment(id: string): Promise<void> {
    const index = this.db.data.comments.findIndex((c) => c.id === id);
    if (index === -1) {
      throw new Error(`Comment with id ${id} not found`);
    }
    this.db.data.comments.splice(index, 1);
    await this.db.write();
  }
}

export const commentRepo = CommentRepo.instance
