package com.tencent.devops.stream.trigger.listener

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.tencent.devops.common.api.enums.ScmType
import com.tencent.devops.common.api.exception.OperationException
import com.tencent.devops.common.api.util.timestampmilli
import com.tencent.devops.common.event.dispatcher.pipeline.mq.MQ
import com.tencent.devops.common.event.pojo.pipeline.PipelineBuildQualityCheckBroadCastEvent
import com.tencent.devops.common.webhook.pojo.code.git.GitEvent
import com.tencent.devops.process.yaml.v2.enums.StreamObjectKind
import com.tencent.devops.stream.config.StreamGitConfig
import com.tencent.devops.stream.dao.GitPipelineResourceDao
import com.tencent.devops.stream.dao.GitRequestEventBuildDao
import com.tencent.devops.stream.dao.GitRequestEventDao
import com.tencent.devops.stream.dao.StreamBasicSettingDao
import com.tencent.devops.stream.trigger.actions.BaseAction
import com.tencent.devops.stream.trigger.actions.EventActionFactory
import com.tencent.devops.stream.trigger.actions.data.StreamTriggerPipeline
import com.tencent.devops.stream.trigger.actions.data.StreamTriggerSetting
import com.tencent.devops.stream.trigger.actions.data.context.BuildFinishData
import com.tencent.devops.stream.trigger.actions.streamActions.StreamMrAction
import com.tencent.devops.stream.trigger.listener.components.SendQualityMrComment
import org.jooq.DSLContext
import org.slf4j.LoggerFactory
import org.springframework.amqp.core.ExchangeTypes
import org.springframework.amqp.rabbit.annotation.Exchange
import org.springframework.amqp.rabbit.annotation.Queue
import org.springframework.amqp.rabbit.annotation.QueueBinding
import org.springframework.amqp.rabbit.annotation.RabbitListener
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import com.tencent.devops.stream.constant.MQ as StreamMQ

@Suppress("ALL")
@Service
class StreamBuildQualityCheckistener @Autowired constructor(
    private val dslContext: DSLContext,
    private val objectMapper: ObjectMapper,
    private val actionFactory: EventActionFactory,
    private val streamGitConfig: StreamGitConfig,
    private val gitRequestEventBuildDao: GitRequestEventBuildDao,
    private val gitRequestEventDao: GitRequestEventDao,
    private val gitPipelineResourceDao: GitPipelineResourceDao,
    private val streamBasicSettingDao: StreamBasicSettingDao,
    private val sendQualityMrComment: SendQualityMrComment
) {

    companion object {
        private val logger = LoggerFactory.getLogger(StreamBuildQualityCheckistener::class.java)
    }

    @RabbitListener(
        bindings = [
            (
                QueueBinding(
                    value = Queue(value = StreamMQ.QUEUE_PIPELINE_BUILD_QUALITY_CHECK_STREAM, durable = "true"),
                    exchange = Exchange(
                        value = MQ.EXCHANGE_PIPELINE_BUILD_QUALITY_CHECK_FANOUT,
                        durable = "true",
                        delayed = "true",
                        type = ExchangeTypes.FANOUT
                    )
                )
                )
        ]
    )
    fun buildQualityCheckListener(buildQualityEvent: PipelineBuildQualityCheckBroadCastEvent) {
        try {
            logger.info("buildQualityCheckListener buildQualityEvent: $buildQualityEvent")
            val buildEvent = gitRequestEventBuildDao.getByBuildId(dslContext, buildQualityEvent.buildId) ?: return
            val requestEvent = gitRequestEventDao.getWithEvent(dslContext, buildEvent.eventId) ?: return
            val pipelineId = buildEvent.pipelineId

            val pipeline = gitPipelineResourceDao.getPipelinesInIds(
                dslContext = dslContext,
                gitProjectId = null,
                pipelineIds = listOf(pipelineId)
            ).getOrNull(0)?.let {
                StreamTriggerPipeline(
                    gitProjectId = it.gitProjectId.toString(),
                    pipelineId = it.pipelineId,
                    filePath = it.filePath,
                    displayName = it.displayName,
                    enabled = it.enabled,
                    creator = it.creator
                )
            } ?: throw OperationException("stream pipeline not exist")

            // 改为利用pipeline信息反查projectId 保证流水线和项目是绑定的
            val setting = streamBasicSettingDao.getSetting(dslContext, pipeline.gitProjectId.toLong())?.let {
                StreamTriggerSetting(it)
            } ?: throw OperationException("stream all projectCode not exist")

            // 加载action，并填充上下文，手动和定时触发需要自己的事件
            val action = when (streamGitConfig.getScmType()) {
                ScmType.CODE_GIT -> when (requestEvent.objectKind) {
                    StreamObjectKind.MANUAL.value -> actionFactory.loadManualAction(
                        setting = setting,
                        event = objectMapper.readValue(requestEvent.event)
                    )
                    StreamObjectKind.SCHEDULE.value -> actionFactory.loadScheduleAction(
                        setting = setting,
                        event = objectMapper.readValue(requestEvent.event)
                    )
                    else -> actionFactory.load(objectMapper.readValue<GitEvent>(requestEvent.event))
                } ?: throw OperationException("stream not support action ${requestEvent.event}")
                else -> TODO("对接其他Git平台时需要补充")
            }

            action.data.setting = setting
            action.data.context.pipeline = pipeline
            action.data.context.finishData = BuildFinishData(
                streamBuildId = buildEvent.id,
                eventId = buildEvent.eventId,
                version = buildEvent.version,
                normalizedYaml = buildEvent.normalizedYaml,
                projectId = buildQualityEvent.projectId,
                pipelineId = buildQualityEvent.pipelineId,
                userId = buildQualityEvent.userId,
                buildId = buildQualityEvent.buildId,
                status = buildQualityEvent.status,
                startTime = buildEvent.createTime.timestampmilli(),
                stageId = null
            )
            action.data.context.requestEventId = requestEvent.id

            if (!action.checkSend()) {
                return
            }

            sendQualityMrComment.sendMrComment(
                action = action as StreamMrAction,
                ruleIds = buildQualityEvent.ruleIds
                    ?: throw RuntimeException("${buildQualityEvent.buildId} have none ruleids")
            )
        } catch (e: Exception) {
            logger.warn("buildQualityCheckListener ${buildQualityEvent.buildId} error: ${e.message}")
        }
    }

    private fun BaseAction.checkSend(): Boolean {
        with(this) {
            if (!data.setting.enableMrComment) {
                return false
            }
            if (this.metaData.streamObjectKind != StreamObjectKind.MERGE_REQUEST) {
                return false
            }
        }
        return true
    }
}
