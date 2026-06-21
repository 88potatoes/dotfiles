import { db } from "../lib/db.ts";
import { CommentEntity, CommentStatus } from "./comments.domain.ts";
import { CommentRecord, CreateCommentInput, UpdateCommentInput } from "./comments.table.ts";


export class CommentRepo {
  private db: typeof db;

  private constructor() {
    this.db = db;
  }

  public static readonly instance = new CommentRepo();

  async getCommentById(id: string): Promise<CommentEntity> {
    const comment = this.db.data.comments.find((comment) => comment.id === id);
    if (!comment) {
      throw new Error(`Comment with id ${id} not found`);
    }
    return this.toDomain(comment);
  }

  async resolveCommentId(input: string): Promise<string> {
    const normalized = input.replace(/-/g, '').toLowerCase();

    const matches = this.db.data.comments.filter(c =>
      c.id.replace(/-/g, '').toLowerCase().startsWith(normalized)
    );

    if (matches.length === 0) {
      throw new Error(`No comment found matching id "${input}"`);
    }
    if (matches.length > 1) {
      const ids = matches.map(m => m.id).join(', ');
      throw new Error(`Ambiguous id "${input}" matches multiple comments: ${ids}`);
    }

    return matches[0].id;
  }

  async getAllComments(): Promise<CommentEntity[]> {
    return this.db.data.comments.map((comment) => this.toDomain(comment));
  }

  async queryComments(filter: { file?: string; status?: CommentStatus }): Promise<CommentEntity[]> {
    return this.db.data.comments
      .filter((comment) => {
        if (filter.file !== undefined && comment.file !== filter.file) return false;
        if (filter.status !== undefined && comment.status !== filter.status) return false;
        return true;
      })
      .map((comment) => this.toDomain(comment));
  }

  async createComment(comment: CreateCommentInput): Promise<CommentEntity> {
    const now = new Date().toISOString();
    const newComment = { ...comment, id: crypto.randomUUID(), createdAt: now, updatedAt: now };
    this.db.data.comments.push(newComment);
    await this.db.write();
    return this.toDomain(newComment);
  }

  async updateComment(updateCommentPayload: UpdateCommentInput): Promise<CommentEntity> {
    const index = this.db.data.comments.findIndex((c) => c.id === updateCommentPayload.id);
    if (index === -1) {
      throw new Error(`Comment with id ${updateCommentPayload.id} not found`);
    }

    const { id, ...updates } = updateCommentPayload;

    const now = new Date().toISOString();
    const updatedComment = { ...this.db.data.comments[index], ...updates, updatedAt: now };
    this.db.data.comments[index] = updatedComment;
    await this.db.write();
    return this.toDomain(updatedComment);
  }

  async deleteComment(id: string): Promise<void> {
    const index = this.db.data.comments.findIndex((c) => c.id === id);
    if (index === -1) {
      throw new Error(`Comment with id ${id} not found`);
    }
    this.db.data.comments.splice(index, 1);
    await this.db.write();
  }

  toDomain(comment: CommentRecord): CommentEntity {
    return {
      id: comment.id,
      file: comment.file,
      startLine: comment.startLine,
      endLine: comment.endLine,
      message: comment.message,
      status: comment.status,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    };
  }
}

export const commentRepo = CommentRepo.instance
