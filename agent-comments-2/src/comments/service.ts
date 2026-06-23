import {
  CommentEntity,
  CommentStatus,
  CreateCommentEntityInput,
  OptionalField,
} from "./comments.domain.ts";
import { CommentRepo } from "./repo.ts";

export class CommentService {
  private commentsRepo: CommentRepo;

  constructor({ commentsRepo }: { commentsRepo: CommentRepo }) {
    this.commentsRepo = commentsRepo;
  }

  async getAllComments(filter?: {
    file?: string;
    status?: CommentStatus;
  }): Promise<CommentEntity[]> {
    return this.commentsRepo.queryComments(filter ?? {});
  }

  async addComment(
    comment: OptionalField<CreateCommentEntityInput, "status">,
  ): Promise<CommentEntity> {
    return this.commentsRepo.createComment({
      status: CommentStatus.Active,
      ...comment,
    });
  }

  async deleteComment(id: string): Promise<void> {
    const fullId = await this.commentsRepo.resolveCommentId(id);
    await this.commentsRepo.deleteComment(fullId);
  }
  async resolveComment(id: string): Promise<CommentEntity> {
    const fullId = await this.commentsRepo.resolveCommentId(id);
    return this.commentsRepo.updateComment({
      id: fullId,
      status: CommentStatus.Resolved,
    });
  }
  async unresolveComment(id: string): Promise<CommentEntity> {
    const fullId = await this.commentsRepo.resolveCommentId(id);
    return this.commentsRepo.updateComment({
      id: fullId,
      status: CommentStatus.Active,
    });
  }

  async clearResolved(): Promise<number> {
    const resolved = await this.commentsRepo.queryComments({
      status: CommentStatus.Resolved,
    });
    for (const c of resolved) {
      await this.commentsRepo.deleteComment(c.id);
    }
    return resolved.length;
  }
}
